import { ref, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import { useToast } from '@/composables/useToast'

/**
 * Composable for tracking n8n jobs with realtime subscriptions
 * Handles job creation, status monitoring, and toast notifications
 */
export function useJobTracking() {
  const authStore = useAuthStore()
  const { showToast } = useToast()

  const activeJobs = ref(new Map()) // Map<job_id, job_data>
  const channels = ref(new Map()) // Map<job_id, channel>

  /**
   * Creates a new n8n job record in the database
   * @param {Object} jobData - Job configuration
   * @param {string} jobData.workflow_type - Type of workflow ('environment_creation', 'avatar_creation', etc.)
   * @param {string} jobData.project_id - Project ID (optional)
   * @param {string} jobData.shot_id - Shot ID (optional)
   * @param {string} jobData.environment_id - Environment ID (optional)
   * @param {string} jobData.avatar_id - Avatar ID (optional)
   * @returns {Object} created job record
   */
  async function createJob(jobData) {
    const { data, error } = await supabase
      .from('n8n_jobs')
      .insert({
        user_id: authStore.user.id,
        workflow_type: jobData.workflow_type,
        project_id: jobData.project_id || null,
        shot_id: jobData.shot_id || null,
        environment_id: jobData.environment_id || null,
        avatar_id: jobData.avatar_id || null,
        status: 'pending',
        retry_count: 0
      })
      .select()
      .single()

    if (error) {
      console.error('Failed to create job:', error)
      throw error
    }

    return data
  }

  /**
   * Subscribes to realtime updates for a specific job
   * @param {string} jobId - The job ID to subscribe to
   * @param {Function} onStatusChange - Optional callback when status changes
   */
  function subscribeToJob(jobId, onStatusChange) {
    // Check if already subscribed
    if (channels.value.has(jobId)) {
      console.log(`Already subscribed to job ${jobId}`)
      return
    }

    const channel = supabase
      .channel(`job-${jobId}`)
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'n8n_jobs',
          filter: `id=eq.${jobId}`
        },
        (payload) => {
          const updatedJob = payload.new

          // Update local state
          activeJobs.value.set(jobId, updatedJob)

          // Show toast notifications
          handleStatusNotification(updatedJob)

          // Call custom callback
          if (onStatusChange) {
            onStatusChange(updatedJob)
          }
        }
      )
      .subscribe((status) => {
        if (status === 'SUBSCRIBED') {
          console.log(`Subscribed to job ${jobId}`)
        }
      })

    channels.value.set(jobId, channel)
  }

  /**
   * Unsubscribes from job updates
   * @param {string} jobId - The job ID to unsubscribe from
   */
  function unsubscribeFromJob(jobId) {
    const channel = channels.value.get(jobId)
    if (channel) {
      channel.unsubscribe()
      channels.value.delete(jobId)
      activeJobs.value.delete(jobId)
      console.log(`Unsubscribed from job ${jobId}`)
    }
  }

  /**
   * Shows toast notification based on job status
   * @param {Object} job - The job object with status
   */
  function handleStatusNotification(job) {
    switch (job.status) {
      case 'generating':
        showToast('Generation in progress...', 'info', 0) // Persistent
        break
      case 'completed':
        showToast('Generation complete!', 'success', 5000)
        break
      case 'failed':
        const errorMsg = job.error_message
          ? `Generation failed: ${job.error_message}`
          : 'Generation failed. Please try again.'
        showToast(errorMsg, 'error', 0) // Persistent error
        break
    }
  }

  /**
   * Fetches all pending jobs for current user and subscribes to them
   * Called on component mount to restore subscriptions after page refresh
   * @returns {Array} list of pending jobs
   */
  async function resubscribeToPendingJobs() {
    try {
      const { data: pendingJobs, error } = await supabase
        .from('n8n_jobs')
        .select('*')
        .eq('user_id', authStore.user.id)
        .in('status', ['pending', 'generating'])
        .order('created_at', { ascending: false })

      if (error) throw error

      // Subscribe to each pending job
      pendingJobs.forEach(job => {
        activeJobs.value.set(job.id, job)
        subscribeToJob(job.id)
      })

      return pendingJobs
    } catch (error) {
      console.error('Failed to resubscribe to pending jobs:', error)
      return []
    }
  }

  /**
   * Checks if a job exists for a given environment
   * Used to prevent duplicate job creation and handle retries
   * @param {string} environmentId - The environment ID
   * @returns {Object|null} existing job or null
   */
  async function getExistingJob(environmentId) {
    const { data, error } = await supabase
      .from('n8n_jobs')
      .select('*')
      .eq('environment_id', environmentId)
      .eq('user_id', authStore.user.id)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (error) {
      console.error('Error checking existing job:', error)
      return null
    }

    return data
  }

  /**
   * Cleanup all subscriptions
   * Called on component unmount
   */
  function cleanup() {
    channels.value.forEach((channel, jobId) => {
      channel.unsubscribe()
    })
    channels.value.clear()
    activeJobs.value.clear()
  }

  // Auto-cleanup on unmount
  onUnmounted(() => {
    cleanup()
  })

  return {
    activeJobs,
    createJob,
    subscribeToJob,
    unsubscribeFromJob,
    resubscribeToPendingJobs,
    getExistingJob,
    cleanup
  }
}
