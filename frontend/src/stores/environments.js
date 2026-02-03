import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from './auth'

export const useEnvironmentsStore = defineStore('environments', () => {
  const authStore = useAuthStore()

  // State
  const environments = ref([])
  const currentEnvironment = ref(null)
  const loading = ref(false)
  const error = ref(null)

  // Realtime subscription
  let envChannel = null

  // Computed
  const activeEnvironments = computed(() =>
    environments.value.filter(e => e.is_active)
  )

  // Get active result image for an environment
  const getActiveResultImage = computed(() => (envId) => {
    const env = environments.value.find(e => e.id === envId)
    if (!env || !env.result_images || env.active_result_index < 0) {
      return null
    }
    return env.result_images[env.active_result_index] || null
  })

  // Get all result images for an environment
  const getResultImages = computed(() => (envId) => {
    const env = environments.value.find(e => e.id === envId)
    return env?.result_images || []
  })

  // Actions
  async function fetchEnvironments() {
    loading.value = true
    error.value = null

    try {
      const { data, error: fetchError } = await supabase
        .from('environments')
        .select('*')
        .eq('user_id', authStore.user.id)
        .order('created_at', { ascending: false })

      if (fetchError) throw fetchError
      environments.value = data || []
    } catch (err) {
      console.error('Error fetching environments:', err)
      error.value = err.message
    } finally {
      loading.value = false
    }
  }

  async function fetchEnvironment(id) {
    loading.value = true
    error.value = null

    try {
      const { data, error: fetchError } = await supabase
        .from('environments')
        .select('*')
        .eq('id', id)
        .single()

      if (fetchError) throw fetchError
      currentEnvironment.value = data
      return data
    } catch (err) {
      console.error('Error fetching environment:', err)
      error.value = err.message
      return null
    } finally {
      loading.value = false
    }
  }

  async function setActiveResultImage(envId, imageIndex) {
    try {
      const { error } = await supabase
        .from('environments')
        .update({ active_result_index: imageIndex })
        .eq('id', envId)

      if (error) throw error

      // Update local state
      const env = environments.value.find(e => e.id === envId)
      if (env) {
        env.active_result_index = imageIndex
      }

      if (currentEnvironment.value?.id === envId) {
        currentEnvironment.value.active_result_index = imageIndex
      }

      console.log('✅ Active result image updated:', envId, 'index:', imageIndex)
    } catch (err) {
      console.error('Error setting active result image:', err)
      throw err
    }
  }

  function subscribeToEnvironments(userId) {
    // Unsubscribe existing if any
    if (envChannel) {
      envChannel.unsubscribe()
    }

    envChannel = supabase
      .channel('environments-realtime')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'environments',
          filter: `user_id=eq.${userId}`
        },
        handleEnvironmentChange
      )
      .subscribe()

    console.log('✅ Subscribed to environments realtime updates')
  }

  function handleEnvironmentChange(payload) {
    const { new: newEnv, old: oldEnv, eventType } = payload

    console.log('🔄 Environment change detected:', eventType, newEnv?.id)

    if (eventType === 'INSERT') {
      // New environment created
      environments.value.unshift(newEnv)
      console.log('➕ New environment added to list:', newEnv.name)
    } else if (eventType === 'UPDATE') {
      // Environment updated (including result_image_url by n8n!)
      const index = environments.value.findIndex(e => e.id === newEnv.id)
      if (index >= 0) {
        environments.value[index] = newEnv
        console.log('✏️ Updated environment in list:', newEnv.name)

        // Log if result_image_url was just added
        if (!oldEnv.result_image_url && newEnv.result_image_url) {
          console.log('🎨 Result image generated for:', newEnv.name)
        }
      }

      // Update current view if viewing this environment
      if (currentEnvironment.value?.id === newEnv.id) {
        // Preserve large fields like result_images that may not be in realtime payload
        currentEnvironment.value = {
          ...currentEnvironment.value,
          ...newEnv,
          // Explicitly preserve result_images if missing from update
          result_images: newEnv.result_images ?? currentEnvironment.value.result_images,
          // Same for any other large JSONB fields
          environment_specs: newEnv.environment_specs ?? currentEnvironment.value.environment_specs
        }
        console.log('📄 Updated current environment view:', newEnv.name)
      }

      // Log variant updates
      if (newEnv.result_images && newEnv.result_images.length > 0) {
        const variantCount = newEnv.result_images.length
        const activeIndex = newEnv.active_result_index
        console.log(`🎨 Environment has ${variantCount} variant(s), active index: ${activeIndex}`)
      }
    } else if (eventType === 'DELETE') {
      // Environment deleted
      environments.value = environments.value.filter(e => e.id !== oldEnv.id)
      if (currentEnvironment.value?.id === oldEnv.id) {
        currentEnvironment.value = null
      }
      console.log('🗑️ Environment deleted from list:', oldEnv.name)
    }
  }

  function unsubscribe() {
    if (envChannel) {
      envChannel.unsubscribe()
      envChannel = null
      console.log('❌ Unsubscribed from environments realtime')
    }
  }

  // Reset store
  function $reset() {
    environments.value = []
    currentEnvironment.value = null
    loading.value = false
    error.value = null
    unsubscribe()
  }

  return {
    // State
    environments,
    currentEnvironment,
    loading,
    error,

    // Computed
    activeEnvironments,
    getActiveResultImage,
    getResultImages,

    // Actions
    fetchEnvironments,
    fetchEnvironment,
    setActiveResultImage,
    subscribeToEnvironments,
    unsubscribe,
    $reset
  }
})
