import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

// Upload timeout in milliseconds (60 seconds - accounts for compression + upload)
const UPLOAD_TIMEOUT_MS = 60000

// Image compression settings
const MAX_IMAGE_DIMENSION = 2048 // Max width or height in pixels
const COMPRESSION_QUALITY = 0.8 // JPEG quality (0.0 - 1.0)

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
   * Compresses an image file to reduce size before upload
   * Uses Canvas API to resize and compress the image
   * @param {File} file - The image file to compress
   * @returns {Promise<File>} compressed image file
   */
  async function compressImage(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader()

      reader.onerror = () => reject(new Error('Failed to read image file'))

      reader.onload = (e) => {
        const img = new Image()

        img.onerror = () => reject(new Error('Failed to load image'))

        img.onload = () => {
          // Calculate new dimensions while maintaining aspect ratio
          let width = img.width
          let height = img.height

          if (width > MAX_IMAGE_DIMENSION || height > MAX_IMAGE_DIMENSION) {
            if (width > height) {
              height = (height / width) * MAX_IMAGE_DIMENSION
              width = MAX_IMAGE_DIMENSION
            } else {
              width = (width / height) * MAX_IMAGE_DIMENSION
              height = MAX_IMAGE_DIMENSION
            }
          }

          // Create canvas and draw resized image
          const canvas = document.createElement('canvas')
          canvas.width = width
          canvas.height = height

          const ctx = canvas.getContext('2d')
          ctx.drawImage(img, 0, 0, width, height)

          // Convert canvas to blob with compression
          canvas.toBlob(
            (blob) => {
              if (!blob) {
                reject(new Error('Failed to compress image'))
                return
              }

              console.log('Image compressed:', {
                originalSize: (file.size / 1024 / 1024).toFixed(2) + ' MB',
                compressedSize: (blob.size / 1024 / 1024).toFixed(2) + ' MB',
                reduction: ((1 - blob.size / file.size) * 100).toFixed(1) + '%'
              })

              // Return the blob directly - Supabase SDK accepts blobs
              // This avoids potential File constructor issues
              resolve(blob)
            },
            'image/jpeg',
            COMPRESSION_QUALITY
          )
        }

        img.src = e.target.result
      }

      reader.readAsDataURL(file)
    })
  }

  /**
   * Generates a unique filename for storage
   * Format: environment_{timestamp}_{random}.{ext} or environment_result_{timestamp}_{random}.{ext}
   * @param {File} file - The file to generate a name for
   * @param {string} imageType - Type of image ('reference' or 'result')
   * @returns {string} unique filename
   */
  function generateFileName(file, imageType = 'reference') {
    const timestamp = Date.now()
    const randomStr = Math.random().toString(36).substring(2, 7)
    const extension = file.name.split('.').pop()
    const prefix = imageType === 'result' ? 'environment_result' : 'environment'
    return `${prefix}_${timestamp}_${randomStr}.${extension}`
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
      currentProgress = Math.min(currentProgress + increment, 95) // Cap at 95%
      uploadProgress.value = Math.floor(currentProgress)
    }, 300) // Update every 300ms

    return interval
  }

  /**
   * Uploads image to Supabase Storage
   * @param {File} file - The image file to upload
   * @param {string} bucket - Storage bucket name (default: 'Environments')
   * @param {string} imageType - Type of image ('reference' or 'result')
   * @returns {Object} result with success flag, URL, path, and error
   */
  async function uploadImage(file, bucket = 'Environments', imageType = 'reference') {
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
      // Compress image before upload
      const compressedFile = await compressImage(file)

      const fileName = generateFileName(file, imageType)
      const userId = authStore.user.id
      const filePath = `${userId}/${fileName}`

      console.log('Starting upload:', {
        bucket,
        filePath,
        blobSize: compressedFile.size,
        blobType: compressedFile.type,
        userId
      })

      // Upload using standard Supabase method - pass blob directly
      const { data, error } = await supabase.storage
        .from(bucket)
        .upload(filePath, compressedFile, {
          cacheControl: '3600',
          upsert: false
        })

      console.log('Upload result:', { data, error })

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
   * @param {string} imageType - Type of image ('reference' or 'result')
   * @param {number} maxRetries - Maximum retry attempts (default: 2)
   * @returns {Object} result with success flag, URL, path, and error
   */
  async function uploadImageWithRetry(file, bucket = 'Environments', imageType = 'reference', maxRetries = 2) {
    let lastError = null

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      if (attempt > 0) {
        console.log(`Upload retry attempt ${attempt}/${maxRetries}`)
        // Exponential backoff: 1s, 2s, 4s...
        await new Promise(resolve => setTimeout(resolve, 1000 * Math.pow(2, attempt - 1)))
      }

      const result = await uploadImage(file, bucket, imageType)

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
