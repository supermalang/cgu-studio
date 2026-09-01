<script setup>
import { ref, computed, onMounted } from 'vue'
import { useSocialAccountsStore } from '@/stores/socialAccounts'
import { useToast } from '@/composables/useToast'
import { PLATFORMS, getPlatform } from '@/lib/platforms'
import Sidebar from '@/components/common/Sidebar.vue'
import AppHeader from '@/components/common/AppHeader.vue'

const accountsStore = useSocialAccountsStore()
const { showToast } = useToast()

const isLoading = ref(true)
const isAdding = ref(false)
const showForm = ref(false)
const form = ref({ platform: 'instagram', handle: '', displayName: '' })

const accounts = computed(() => accountsStore.accounts)
const hasAccounts = computed(() => accounts.value.length > 0)

async function load() {
  isLoading.value = true
  try {
    await accountsStore.fetchAccounts()
  } catch (err) {
    showToast('Failed to load channels.', 'error')
  } finally {
    isLoading.value = false
  }
}

async function addAccount() {
  if (!form.value.handle.trim()) {
    showToast('Enter the account handle.', 'warning')
    return
  }

  isAdding.value = true
  try {
    await accountsStore.addAccount({
      platform: form.value.platform,
      handle: form.value.handle.trim(),
      displayName: form.value.displayName.trim() || null
    })
    showToast('Channel added.', 'success')
    form.value = { platform: 'instagram', handle: '', displayName: '' }
    showForm.value = false
  } catch (err) {
    console.error('Error adding channel:', err)
    // The unique constraint is the error users will actually hit here.
    const message = err.code === '23505'
      ? 'That handle is already connected for this platform.'
      : err.message
    showToast(`Could not add the channel: ${message}`, 'error')
  } finally {
    isAdding.value = false
  }
}

async function toggleActive(account) {
  try {
    await accountsStore.updateAccount(account.id, { is_active: !account.is_active })
    showToast(account.is_active ? 'Channel disconnected.' : 'Channel reconnected.', 'success')
  } catch (err) {
    showToast(`Could not update the channel: ${err.message}`, 'error')
  }
}

onMounted(load)
</script>

<template>
  <div class="min-h-screen bg-neutral-50">
    <Sidebar />
    <AppHeader />

    <main class="ml-64 px-6 py-8">
      <div class="flex items-start justify-between mb-8">
        <div>
          <h1 class="text-4xl font-black text-neutral-900 mb-2">Channels</h1>
          <p class="text-base text-neutral-600">
            The social accounts your posts publish to.
          </p>
        </div>
        <button @click="showForm = !showForm" class="btn-primary">
          {{ showForm ? 'Cancel' : 'Add channel' }}
        </button>
      </div>

      <!-- Add form -->
      <div v-if="showForm" class="card p-6 mb-6">
        <div class="grid grid-cols-3 gap-4">
          <div>
            <label class="input-label" for="channel-platform">Platform</label>
            <select id="channel-platform" v-model="form.platform" class="input-field">
              <option v-for="p in PLATFORMS" :key="p.value" :value="p.value">{{ p.label }}</option>
            </select>
          </div>
          <div>
            <label class="input-label" for="channel-handle">Handle</label>
            <input id="channel-handle" v-model="form.handle" class="input-field" placeholder="@jelika" />
          </div>
          <div>
            <label class="input-label" for="channel-name">Display name</label>
            <input id="channel-name" v-model="form.displayName" class="input-field" placeholder="Jelika Official" />
          </div>
        </div>
        <div class="mt-4">
          <button @click="addAccount" :disabled="isAdding" class="btn-primary">
            {{ isAdding ? 'Adding…' : 'Add channel' }}
          </button>
        </div>
        <p class="text-xs text-neutral-500 mt-3">
          This registers the channel so posts can target it. Publishing credentials live in n8n —
          no access token is ever stored in the app database.
        </p>
      </div>

      <div v-if="isLoading" class="card p-12 text-center text-neutral-500">Loading channels…</div>

      <!-- Empty state -->
      <div v-else-if="!hasAccounts" class="card p-12 text-center">
        <p class="text-lg font-semibold text-neutral-900 mb-1">No channels yet</p>
        <p class="text-sm text-neutral-600 mb-4">
          Add your first social account to start scheduling posts.
        </p>
        <button @click="showForm = true" class="btn-primary">Add channel</button>
      </div>

      <!-- List -->
      <div v-else class="grid grid-cols-3 gap-4">
        <div v-for="account in accounts" :key="account.id" class="card p-5">
          <div class="flex items-center gap-3 mb-3">
            <span
              class="w-3 h-3 rounded-full"
              :style="{ backgroundColor: getPlatform(account.platform).color }"
            />
            <span class="font-bold text-neutral-900">{{ getPlatform(account.platform).label }}</span>
            <span
              class="ml-auto text-[10px] px-2 py-0.5 rounded-full font-medium"
              :class="account.is_active
                ? 'bg-success-50 text-success-700'
                : 'bg-neutral-100 text-neutral-500'"
            >
              {{ account.is_active ? 'Connected' : 'Disconnected' }}
            </span>
          </div>

          <p class="text-sm font-medium text-neutral-900">{{ account.handle }}</p>
          <p v-if="account.display_name" class="text-sm text-neutral-500">{{ account.display_name }}</p>
          <p class="text-xs text-neutral-400 mt-2">
            Caption limit {{ getPlatform(account.platform).charLimit.toLocaleString() }} characters
          </p>

          <button @click="toggleActive(account)" class="btn-ghost text-sm mt-3 px-0">
            {{ account.is_active ? 'Disconnect' : 'Reconnect' }}
          </button>
        </div>
      </div>
    </main>
  </div>
</template>
