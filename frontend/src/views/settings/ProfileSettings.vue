<script setup>
import Sidebar from '@/components/common/Sidebar.vue'
import AppHeader from '@/components/common/AppHeader.vue'
import ProfileForm from '@/components/settings/ProfileForm.vue'
import AccountInfo from '@/components/settings/AccountInfo.vue'
import ApiKeyManager from '@/components/settings/ApiKeyManager.vue'
</script>

<template>
  <div class="flex min-h-screen bg-neutral-50">
    <Sidebar />

    <div class="flex-1 ml-64">
      <AppHeader />

      <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Page Header -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-neutral-900">
            Profile Settings
          </h1>
          <p class="text-gray-600 mt-2">
            Manage your personal information and preferences
          </p>
        </div>

        <!-- Two-Column Layout -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <!-- Left Column - Editable Forms (2/3 width) -->
          <div class="lg:col-span-2 space-y-6">
            <ProfileForm />
            <ApiKeyManager />
          </div>

          <!-- Right Column - Read-only Info (1/3 width) -->
          <div class="lg:col-span-1">
            <AccountInfo />
          </div>
        </div>
      </main>
    </div>
  </div>
</template>
