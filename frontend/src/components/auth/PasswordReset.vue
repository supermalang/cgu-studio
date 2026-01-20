<script setup>
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

const email = ref('')
const isLoading = ref(false)
const error = ref(null)
const success = ref(false)

async function handleResetPassword() {
  if (!email.value) {
    error.value = 'Please enter your email address'
    return
  }

  isLoading.value = true
  error.value = null
  success.value = false

  try {
    const { error: resetError } = await authStore.resetPassword(email.value)

    if (resetError) {
      error.value = resetError.message
      return
    }

    success.value = true
  } catch (err) {
    error.value = 'An unexpected error occurred'
    console.error('Password reset error:', err)
  } finally {
    isLoading.value = false
  }
}
</script>

<template>
  <div class="w-full max-w-md">
    <div class="card">
      <h1 class="text-2xl font-bold text-neutral-900 mb-2">Reset your password</h1>
      <p class="text-gray-600 mb-6">
        Enter your email address and we'll send you a link to reset your password.
      </p>

      <!-- Success Message -->
      <div v-if="success" class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg mb-4">
        Password reset email sent! Check your inbox for further instructions.
      </div>

      <!-- Error Message -->
      <div v-if="error" class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-4">
        {{ error }}
      </div>

      <!-- Reset Form -->
      <form v-if="!success" @submit.prevent="handleResetPassword" class="space-y-4">
        <div>
          <label for="email" class="block text-sm font-medium text-neutral-900 mb-1">
            Email
          </label>
          <input
            id="email"
            v-model="email"
            type="email"
            required
            class="input-field"
            placeholder="you@example.com"
            :disabled="isLoading"
          />
        </div>

        <button
          type="submit"
          :disabled="isLoading"
          class="btn-primary w-full"
        >
          {{ isLoading ? 'Sending...' : 'Send reset link' }}
        </button>
      </form>

      <!-- Back to Login -->
      <div class="mt-6 text-center">
        <router-link to="/auth/login" class="text-sm text-primary hover:underline">
          Back to log in
        </router-link>
      </div>
    </div>
  </div>
</template>
