import { ref, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'

export function useProfileSettings() {
  const authStore = useAuthStore()
  const isLoading = ref(false)
  const error = ref(null)

  const profile = computed(() => authStore.profile)

  function validateEmail(email) {
    if (!email) return true // Allow empty emails (optional field)
    const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return regex.test(email)
  }

  function validateUrl(url) {
    if (!url) return true // Allow empty URLs (optional field)
    try {
      new URL(url)
      return true
    } catch {
      return false
    }
  }

  function validateName(name) {
    return name && name.trim().length > 0 && name.trim().length <= 100
  }

  async function updateProfile(updates) {
    isLoading.value = true
    error.value = null

    // Validate before updating
    if (updates.full_name !== undefined && !validateName(updates.full_name)) {
      error.value = 'Name must be between 1 and 100 characters'
      isLoading.value = false
      return { data: null, error: error.value }
    }

    if (updates.avatar_url !== undefined && !validateUrl(updates.avatar_url)) {
      error.value = 'Invalid avatar URL format'
      isLoading.value = false
      return { data: null, error: error.value }
    }

    try {
      const { data, error: updateError } = await authStore.updateProfile(updates)

      if (updateError) throw new Error(updateError)

      return { data, error: null }
    } catch (err) {
      console.error('Error updating profile:', err)
      error.value = err.message
      return { data: null, error: err.message }
    } finally {
      isLoading.value = false
    }
  }

  return {
    profile,
    isLoading,
    error,
    validateEmail,
    validateUrl,
    validateName,
    updateProfile
  }
}
