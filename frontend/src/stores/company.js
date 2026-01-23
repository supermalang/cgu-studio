import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export const useCompanyStore = defineStore('company', () => {
  // State
  const settings = ref(null)
  const loading = ref(false)
  const error = ref(null)

  // Default values
  const companyName = ref('UCG Studio')
  const companyDescription = ref('')
  const supportEmail = ref('')
  const contactPhone = ref('')
  const contactEmail = ref('')
  const logoUrl = ref('')

  // Actions
  async function initialize() {
    // Only fetch if we haven't already
    if (settings.value) return

    await fetchSettings()
  }

  async function fetchSettings() {
    loading.value = true
    error.value = null

    try {
      const { data, error: fetchError } = await supabase
        .from('admin_settings')
        .select('company_settings')
        .eq('id', 1)
        .single()

      if (fetchError) throw fetchError

      settings.value = data

      // Update computed values from company_settings
      if (data?.company_settings) {
        companyName.value = data.company_settings.company_name || 'UCG Studio'
        companyDescription.value = data.company_settings.description || ''
        supportEmail.value = data.company_settings.support_email || ''
        contactPhone.value = data.company_settings.contact_phone || ''
        contactEmail.value = data.company_settings.contact_email || ''
        logoUrl.value = data.company_settings.logo_url || ''
      }
    } catch (err) {
      console.error('Error fetching company settings:', err)
      error.value = err.message
      // Keep default values on error
    } finally {
      loading.value = false
    }
  }

  // Refresh settings (call this after admin updates)
  async function refresh() {
    await fetchSettings()
  }

  return {
    // State
    settings,
    loading,
    error,

    // Company fields
    companyName,
    companyDescription,
    supportEmail,
    contactPhone,
    contactEmail,
    logoUrl,

    // Actions
    initialize,
    refresh
  }
})
