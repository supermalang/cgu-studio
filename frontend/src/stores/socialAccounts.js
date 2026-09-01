import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from './auth'

export const useSocialAccountsStore = defineStore('socialAccounts', () => {
  const authStore = useAuthStore()

  const accounts = ref([])
  const loading = ref(false)
  const error = ref(null)

  const activeAccounts = computed(() => accounts.value.filter(a => a.is_active))

  const byPlatform = computed(() =>
    accounts.value.reduce((acc, a) => {
      ;(acc[a.platform] = acc[a.platform] || []).push(a)
      return acc
    }, {})
  )

  async function fetchAccounts() {
    loading.value = true
    error.value = null

    try {
      const { data, error: fetchError } = await supabase
        .from('social_accounts')
        .select('*')
        .eq('user_id', authStore.user.id)
        .order('platform', { ascending: true })

      if (fetchError) throw fetchError
      accounts.value = data || []
    } catch (err) {
      console.error('Error fetching social accounts:', err)
      error.value = err.message
    } finally {
      loading.value = false
    }
  }

  async function addAccount({ platform, handle, displayName = null }) {
    const userId = authStore.user.id

    const { data, error: insertError } = await supabase
      .from('social_accounts')
      .insert({
        user_id: userId,
        platform,
        handle: handle.startsWith('@') ? handle : `@${handle}`,
        display_name: displayName,
        connected_at: new Date().toISOString(),
        created_by: userId,
        updated_by: userId
      })
      .select()
      .single()

    if (insertError) throw insertError

    accounts.value.push(data)
    return data
  }

  async function updateAccount(id, changes) {
    const { data, error: updateError } = await supabase
      .from('social_accounts')
      .update(changes)
      .eq('id', id)
      .select()
      .single()

    if (updateError) throw updateError

    const index = accounts.value.findIndex(a => a.id === id)
    if (index >= 0) accounts.value[index] = data
    return data
  }

  // Disconnecting keeps the row so published posts keep their channel history;
  // only a hard delete would orphan them.
  async function disconnectAccount(id) {
    return updateAccount(id, { is_active: false })
  }

  async function deleteAccount(id) {
    const { error: deleteError } = await supabase.from('social_accounts').delete().eq('id', id)
    if (deleteError) throw deleteError

    accounts.value = accounts.value.filter(a => a.id !== id)
  }

  function $reset() {
    accounts.value = []
    loading.value = false
    error.value = null
  }

  return {
    accounts,
    loading,
    error,
    activeAccounts,
    byPlatform,
    fetchAccounts,
    addAccount,
    updateAccount,
    disconnectAccount,
    deleteAccount,
    $reset
  }
})
