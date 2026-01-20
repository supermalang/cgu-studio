import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export const useAuthStore = defineStore('auth', () => {
  // State
  const user = ref(null)
  const profile = ref(null)
  const session = ref(null)
  const loading = ref(true)

  // Getters
  const isAuthenticated = computed(() => !!user.value)
  const isAdmin = computed(() => profile.value?.role === 'admin')
  const creditBalance = computed(() => profile.value?.credit_balance || 0)

  // Actions
  async function initialize() {
    try {
      loading.value = true

      // Get current session
      const { data: { session: currentSession } } = await supabase.auth.getSession()

      if (currentSession) {
        session.value = currentSession
        user.value = currentSession.user
        await fetchProfile()
      }

      // Listen for auth changes
      supabase.auth.onAuthStateChange(async (_event, newSession) => {
        session.value = newSession
        user.value = newSession?.user || null

        if (newSession?.user) {
          await fetchProfile()
        } else {
          profile.value = null
        }
      })
    } catch (error) {
      console.error('Auth initialization error:', error)
    } finally {
      loading.value = false
    }
  }

  async function fetchProfile() {
    if (!user.value) return

    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.value.id)
        .single()

      if (error) throw error
      profile.value = data
    } catch (error) {
      console.error('Error fetching profile:', error)
    }
  }

  async function signUp(email, password, fullName) {
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            full_name: fullName
          }
        }
      })

      if (error) throw error

      // Create profile manually if trigger doesn't work
      if (data.user) {
        try {
          const { error: profileError } = await supabase
            .from('profiles')
            .insert({
              id: data.user.id,
              full_name: fullName,
              created_by: data.user.id,
              updated_by: data.user.id
            })

          // Ignore error if profile already exists (trigger worked)
          if (profileError && !profileError.message.includes('duplicate')) {
            console.error('Profile creation error:', profileError)
          }
        } catch (profileErr) {
          console.error('Failed to create profile:', profileErr)
        }
      }

      return { data, error: null }
    } catch (error) {
      console.error('Signup error:', error)
      return { data: null, error }
    }
  }

  async function signIn(email, password) {
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password
      })

      if (error) throw error
      return { data, error: null }
    } catch (error) {
      console.error('Login error:', error)
      return { data: null, error }
    }
  }

  async function signInWithGoogle() {
    try {
      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: `${import.meta.env.VITE_APP_URL}/auth/callback`
        }
      })

      if (error) throw error
      return { data, error: null }
    } catch (error) {
      console.error('Google login error:', error)
      return { data: null, error }
    }
  }

  async function signOut() {
    try {
      const { error } = await supabase.auth.signOut()
      if (error) throw error

      user.value = null
      profile.value = null
      session.value = null

      return { error: null }
    } catch (error) {
      console.error('Logout error:', error)
      return { error }
    }
  }

  async function resetPassword(email) {
    try {
      const { data, error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${import.meta.env.VITE_APP_URL}/auth/reset-password`
      })

      if (error) throw error
      return { data, error: null }
    } catch (error) {
      console.error('Password reset error:', error)
      return { data: null, error }
    }
  }

  async function updatePassword(newPassword) {
    try {
      const { data, error } = await supabase.auth.updateUser({
        password: newPassword
      })

      if (error) throw error
      return { data, error: null }
    } catch (error) {
      console.error('Password update error:', error)
      return { data: null, error }
    }
  }

  async function updateProfile(updates) {
    if (!user.value) return { error: 'No user logged in' }

    try {
      const { data, error } = await supabase
        .from('profiles')
        .update(updates)
        .eq('id', user.value.id)
        .select()
        .single()

      if (error) throw error
      profile.value = data
      return { data, error: null }
    } catch (error) {
      console.error('Profile update error:', error)
      return { data: null, error }
    }
  }

  return {
    // State
    user,
    profile,
    session,
    loading,

    // Getters
    isAuthenticated,
    isAdmin,
    creditBalance,

    // Actions
    initialize,
    fetchProfile,
    signUp,
    signIn,
    signInWithGoogle,
    signOut,
    resetPassword,
    updatePassword,
    updateProfile
  }
})
