<script setup>
import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

const profile = computed(() => authStore.profile)

const statusBadgeClass = computed(() => {
  if (!profile.value) return 'badge-neutral'
  return profile.value.status === 'active' ? 'badge-success' : 'badge-error'
})

const statusText = computed(() => {
  if (!profile.value) return 'Unknown'
  return profile.value.status === 'active' ? 'Active' : 'Suspended'
})

function formatNumber(num) {
  return new Intl.NumberFormat('en-US').format(num || 0)
}

function formatBytes(bytes) {
  if (!bytes) return '0 B'
  const mb = bytes / (1024 * 1024)
  if (mb < 1) return `${(bytes / 1024).toFixed(2)} KB`
  return `${mb.toFixed(2)} MB`
}

function formatDate(dateString) {
  if (!dateString) return 'N/A'
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
}

const storagePercentage = computed(() => {
  if (!profile.value) return 0
  const maxStorageBytes = 1 * 1024 * 1024 * 1024 // 1 GB in bytes
  return (profile.value.total_storage_used / maxStorageBytes) * 100
})
</script>

<template>
  <div class="card">
    <div class="px-6 py-4 border-b border-gray-200">
      <h3 class="text-lg font-semibold text-neutral-900">Account Information</h3>
      <p class="text-sm text-gray-600 mt-1">View your account details</p>
    </div>

    <div class="p-6 space-y-4">
      <!-- Account Status -->
      <div>
        <label class="text-sm font-medium text-gray-700">Account Status</label>
        <div class="mt-1">
          <span :class="['badge', statusBadgeClass]">{{ statusText }}</span>
        </div>
      </div>

      <!-- Credit Balance -->
      <div>
        <label class="text-sm font-medium text-gray-700">Credit Balance</label>
        <p class="mt-1 text-2xl font-bold text-primary-600">
          {{ formatNumber(profile?.credit_balance) }}
        </p>
        <p class="text-sm text-gray-500">credits available</p>
      </div>

      <!-- Storage Used -->
      <div>
        <label class="text-sm font-medium text-gray-700">Storage Used</label>
        <div class="mt-2">
          <div class="flex justify-between text-sm text-gray-600 mb-1">
            <span>{{ formatBytes(profile?.total_storage_used) }}</span>
            <span>1 GB</span>
          </div>
          <div class="w-full bg-gray-200 rounded-full h-2">
            <div
              class="bg-primary-600 h-2 rounded-full transition-all"
              :style="{ width: `${Math.min(storagePercentage, 100)}%` }"
            ></div>
          </div>
          <p class="text-xs text-gray-500 mt-1">
            {{ storagePercentage.toFixed(1) }}% used
          </p>
        </div>
      </div>

      <!-- Member Since -->
      <div>
        <label class="text-sm font-medium text-gray-700">Member Since</label>
        <p class="mt-1 text-base text-gray-900">
          {{ formatDate(profile?.created_at) }}
        </p>
      </div>
    </div>
  </div>
</template>
