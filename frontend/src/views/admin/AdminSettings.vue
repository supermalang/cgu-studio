<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { onBeforeRouteLeave } from 'vue-router'
import Sidebar from '@/components/common/Sidebar.vue'
import AppHeader from '@/components/common/AppHeader.vue'
import CompanySettingsForm from '@/components/settings/admin/CompanySettingsForm.vue'
import PlatformSettingsForm from '@/components/settings/admin/PlatformSettingsForm.vue'
import CreditPackagesManager from '@/components/settings/admin/CreditPackagesManager.vue'
import AuditInfo from '@/components/settings/admin/AuditInfo.vue'
import { useAdminSettings } from '@/composables/useAdminSettings'
import { useToast } from '@/composables/useToast'
import { useCompanyStore } from '@/stores/company'

const { settings, isLoading, error, isDirty, fetchSettings, updateCompanySettings, updatePlatformSettings, updateCreditPackages, saveAll, reset } = useAdminSettings()
const { showToast } = useToast()
const companyStore = useCompanyStore()

const companyFormRef = ref(null)
const platformFormRef = ref(null)

onMounted(async () => {
  await fetchSettings()
})

function handleCompanyUpdate(data) {
  updateCompanySettings(data)
}

function handlePlatformUpdate(data) {
  updatePlatformSettings(data)
}

function handlePackagesUpdate(packages) {
  updateCreditPackages(packages)
}

async function handleSave() {
  // Check for validation errors in forms
  const companyErrors = companyFormRef.value?.errors || {}
  const platformErrors = platformFormRef.value?.errors || {}

  const hasErrors = Object.values(companyErrors).some(err => err) ||
                    Object.values(platformErrors).some(err => err)

  if (hasErrors) {
    showToast('Please fix validation errors before saving', 'error')
    return
  }

  const { error: saveError } = await saveAll()

  if (saveError) {
    showToast(`Failed to save settings: ${saveError}`, 'error')
  } else {
    showToast('Settings saved successfully', 'success')
    // Refresh company store to update cached data across the app
    await companyStore.refresh()
  }
}

function handleCancel() {
  if (isDirty.value && !confirm('You have unsaved changes. Are you sure you want to discard them?')) {
    return
  }
  reset()
}

// Warn before leaving with unsaved changes
onBeforeRouteLeave((to, from, next) => {
  if (isDirty.value) {
    const answer = confirm('You have unsaved changes. Do you really want to leave?')
    if (answer) {
      next()
    } else {
      next(false)
    }
  } else {
    next()
  }
})

// Warn before closing/refreshing with unsaved changes
onMounted(() => {
  window.addEventListener('beforeunload', handleBeforeUnload)
})

onBeforeUnmount(() => {
  window.removeEventListener('beforeunload', handleBeforeUnload)
})

function handleBeforeUnload(e) {
  if (isDirty.value) {
    e.preventDefault()
    e.returnValue = ''
  }
}
</script>

<template>
  <div class="flex min-h-screen bg-neutral-50">
    <Sidebar />

    <div class="flex-1 ml-64">
      <AppHeader />

      <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Page Header -->
        <div class="mb-8 flex items-center justify-between">
          <div>
            <h1 class="text-3xl font-bold text-neutral-900">
              Admin Settings
            </h1>
            <p class="text-gray-600 mt-2">
              Manage platform-wide configuration and settings
            </p>
          </div>
          <div v-if="isDirty" class="badge badge-warning">
            Unsaved changes
          </div>
        </div>

        <!-- Loading State -->
        <div v-if="isLoading && !settings" class="text-center py-12">
          <div class="spinner mx-auto"></div>
          <p class="text-gray-600 mt-4">Loading settings...</p>
        </div>

        <!-- Error State -->
        <div v-else-if="error && !settings" class="alert-error">
          <p class="font-semibold">Failed to load settings</p>
          <p class="text-sm mt-1">{{ error }}</p>
          <button @click="fetchSettings" class="btn-primary btn-sm mt-4">
            Retry
          </button>
        </div>

        <!-- Settings Forms -->
        <div v-else-if="settings" class="space-y-6">
          <!-- Company Settings -->
          <CompanySettingsForm
            ref="companyFormRef"
            :settings="settings"
            @update="handleCompanyUpdate"
          />

          <!-- Platform Settings -->
          <PlatformSettingsForm
            ref="platformFormRef"
            :settings="settings"
            @update="handlePlatformUpdate"
          />

          <!-- Credit Packages -->
          <CreditPackagesManager
            :settings="settings"
            @update="handlePackagesUpdate"
          />

          <!-- Audit Info -->
          <AuditInfo :settings="settings" />

          <!-- Action Buttons -->
          <div class="flex items-center justify-end gap-3 pt-4 border-t border-gray-200">
            <button
              @click="handleCancel"
              :disabled="isLoading || !isDirty"
              class="btn-ghost"
            >
              Cancel
            </button>
            <button
              @click="handleSave"
              :disabled="isLoading || !isDirty"
              class="btn-primary"
            >
              <span v-if="isLoading" class="spinner mr-2"></span>
              {{ isLoading ? 'Saving...' : 'Save Changes' }}
            </button>
          </div>
        </div>
      </main>
    </div>
  </div>
</template>
