import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

// Simple hash function for comparing objects (much faster than JSON.stringify)
function simpleHash(obj) {
  if (!obj) return ''
  let hash = 0
  const str = JSON.stringify(obj)
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i)
    hash = ((hash << 5) - hash) + char
    hash = hash & hash // Convert to 32bit integer
  }
  return hash.toString()
}

export function useAdminSettings() {
  const settings = ref(null)
  const isLoading = ref(false)
  const error = ref(null)
  const originalSettings = ref(null)
  const originalHash = ref('')
  const currentHash = ref('')

  const isDirty = computed(() => {
    if (!settings.value || !originalSettings.value) return false
    // Only compute hash when settings actually change
    const newHash = simpleHash(settings.value)
    currentHash.value = newHash
    return currentHash.value !== originalHash.value
  })

  async function fetchSettings() {
    isLoading.value = true
    error.value = null

    try {
      const { data, error: fetchError } = await supabase
        .from('admin_settings')
        .select('*')
        .eq('id', 1)
        .single()

      if (fetchError) throw fetchError

      settings.value = data
      originalSettings.value = JSON.parse(JSON.stringify(data))
      originalHash.value = simpleHash(data)
      currentHash.value = originalHash.value
    } catch (err) {
      console.error('Error fetching admin settings:', err)
      error.value = err.message
    } finally {
      isLoading.value = false
    }
  }

  async function updateCompanySettings(updates) {
    if (!settings.value) return { error: 'Settings not loaded' }

    // Merge updates with existing company settings
    const mergedCompanySettings = {
      ...settings.value.company_settings,
      ...updates
    }

    settings.value.company_settings = mergedCompanySettings
  }

  async function updatePlatformSettings(updates) {
    if (!settings.value) return { error: 'Settings not loaded' }

    // Merge updates with existing platform settings
    const mergedPlatformSettings = {
      ...settings.value.platform_settings,
      ...updates
    }

    settings.value.platform_settings = mergedPlatformSettings
  }

  async function updateCreditPackages(packages) {
    if (!settings.value) return { error: 'Settings not loaded' }

    // Replace entire credit packages array
    settings.value.credit_packages = packages
  }

  async function saveAll() {
    if (!settings.value) return { error: 'Settings not loaded' }

    isLoading.value = true
    error.value = null

    try {
      const { data, error: updateError } = await supabase
        .from('admin_settings')
        .update({
          company_settings: settings.value.company_settings,
          platform_settings: settings.value.platform_settings,
          credit_packages: settings.value.credit_packages
        })
        .eq('id', 1)
        .select()
        .single()

      if (updateError) throw updateError

      // Update both settings and originalSettings to the saved state
      settings.value = data
      originalSettings.value = JSON.parse(JSON.stringify(data))
      originalHash.value = simpleHash(data)
      currentHash.value = originalHash.value

      return { data, error: null }
    } catch (err) {
      console.error('Error saving admin settings:', err)
      error.value = err.message
      return { data: null, error: err.message }
    } finally {
      isLoading.value = false
    }
  }

  function reset() {
    if (originalSettings.value) {
      settings.value = JSON.parse(JSON.stringify(originalSettings.value))
      currentHash.value = originalHash.value
    }
  }

  return {
    settings,
    isLoading,
    error,
    isDirty,
    fetchSettings,
    updateCompanySettings,
    updatePlatformSettings,
    updateCreditPackages,
    saveAll,
    reset
  }
}
