import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

// Upload timeout in milliseconds (30 seconds)
const UPLOAD_TIMEOUT_MS = 30000

/**
 * Composable for handling image uploads to Supabase Storage
 * Provides validation, upload, and deletion functionality for environment images
 */
export function useImageUpload() {
  const authStore = useAuthStore()
  const isUploading = ref(false)
  const uploadProgress = ref(0)
  const uploadError = ref(null)

  /**
   * Validates image file before upload
   * @param {File} file - The file to validate
   * @returns {Object} validation result with valid flag and error message
   */
  function validateImage(file) {
    const maxSize = 5 * 1024 * 1024 // 5MB
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp']

    if (!file) {
      return { valid: false, error: 'No file selected' }
    }

    if (!allowedTypes.includes(file.type)) {
      return {
        valid: false,
        error: 'Invalid file type. Please upload JPG, PNG, or WebP images.'
      }
    }

    if (file.size > maxSize) {
      return {
        valid: false,
        error: 'File size exceeds 5MB limit. Please compress your image.'
      }
    }

    return { valid: true, error: null }
  }

  /**
   * Generates a unique filename for storage
   * Format: environment_{timestamp}_{random}.{ext}
   * @param {File} file - The file to generate a name for
   * @returns {string} unique filename
   */
  function generateFileName(file) {
    const timestamp = Date.now()
    const randomStr = Math.random().toString(36).substring(2, 7)
    const extension = file.name.split('.').pop()
    return `environment_${timestamp}_${randomStr}.${extension}`
  }

  /**
   * Simulates upload progress with exponential slowdown
   * Progress moves quickly at start, slows near completion
   * @returns {number} interval ID for clearing
   */
  function startProgressSimulation() {
    let currentProgress = 0

    const interval = setInterval(() => {
      // Exponential slowdown (fast at start, slow near end)
      const increment = (100 - currentProgress) * 0.1
      currentProgress = Math.min(currentProgress + increment, 90) // Cap at 90%
      uploadProgress.value = Math.floor(currentProgress)
    }, 300) // Update every 300ms

    return interval
  }

  /**
   * Uploads image to Supabase Storage
   * @param {File} file - The image file to upload
   * @param {string} bucket - Storage bucket name (default: 'Environments')
   * @returns {Object} result with success flag, URL, path, and error
   */
  async function uploadImage(file, bucket = 'Environments') {
    // Validate file
    const validation = validateImage(file)
    if (!validation.valid) {
      uploadError.value = validation.error
      return { success: false, url: null, path: null, error: validation.error }
    }

    isUploading.value = true
    uploadProgress.value = 0
    uploadError.value = null

    // Start progress simulation
    const progressInterval = startProgressSimulation()

    try {
      const fileName = generateFileName(file)
      const userId = authStore.user.id
      const filePath = `${userId}/${fileName}`

      // Create upload promise
      const uploadPromise = supabase.storage
        .from(bucket)
        .upload(filePath, file, {
          cacheControl: '3600',
          upsert: false
        })

      // Create timeout promise
      const timeoutPromise = new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Upload timeout: Request took too long')), UPLOAD_TIMEOUT_MS)
      )

      // Race them - first to complete/fail wins
      const { error } = await Promise.race([uploadPromise, timeoutPromise])

      if (error) throw error

      // Get signed URL (for private buckets)
      const { data: urlData, error: signError } = await supabase.storage
        .from(bucket)
        .createSignedUrl(filePath, 31536000) // 1 year expiration (31536000 seconds)

      if (signError) throw signError

      // Complete progress
      clearInterval(progressInterval)
      uploadProgress.value = 100
      isUploading.value = false

      return {
        success: true,
        url: urlData.signedUrl,
        path: filePath,
        error: null
      }

    } catch (error) {
      console.error('Image upload failed:', error)
      uploadError.value = error.message

      // Clear progress simulation
      clearInterval(progressInterval)
      uploadProgress.value = 0
      isUploading.value = false

      return {
        success: false,
        url: null,
        path: null,
        error: error.message
      }
    }
  }

  /**
   * Deletes image from storage
   * @param {string} filePath - Path to the file in storage
   * @param {string} bucket - Storage bucket name (default: 'Environments')
   * @returns {boolean} true if deletion successful
   */
  async function deleteImage(filePath, bucket = 'Environments') {
    try {
      const { error } = await supabase.storage
        .from(bucket)
        .remove([filePath])

      if (error) throw error
      return true
    } catch (error) {
      console.error('Image deletion failed:', error)
      return false
    }
  }

  /**
   * Uploads image with automatic retry on failure
   * Uses exponential backoff between retry attempts
   * @param {File} file - The image file to upload
   * @param {string} bucket - Storage bucket name (default: 'Environments')
   * @param {number} maxRetries - Maximum retry attempts (default: 2)
   * @returns {Object} result with success flag, URL, path, and error
   */
  async function uploadImageWithRetry(file, bucket = 'Environments', maxRetries = 2) {
    let lastError = null

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      if (attempt > 0) {
        console.log(`Upload retry attempt ${attempt}/${maxRetries}`)
        // Exponential backoff: 1s, 2s, 4s...
        await new Promise(resolve => setTimeout(resolve, 1000 * Math.pow(2, attempt - 1)))
      }

      const result = await uploadImage(file, bucket)

      if (result.success) {
        return result
      }

      lastError = result.error

      // Don't retry on validation errors (they won't succeed anyway)
      if (result.error.includes('Invalid file type') ||
          result.error.includes('File size exceeds')) {
        break
      }
    }

    return {
      success: false,
      url: null,
      path: null,
      error: lastError || 'Upload failed after retries'
    }
  }

  return {
    isUploading,
    uploadProgress,
    uploadError,
    validateImage,
    uploadImage,
    uploadImageWithRetry,
    deleteImage
  }
}
