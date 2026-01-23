<script setup>
import { ref, watch, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'

const props = defineProps({
  settings: {
    type: Object,
    default: null
  }
})

const updatedByUser = ref(null)

async function fetchUpdatedByUser() {
  if (!props.settings?.updated_by) return

  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('full_name')
      .eq('id', props.settings.updated_by)
      .single()

    if (error) throw error
    updatedByUser.value = data?.full_name || 'Unknown User'
  } catch (err) {
    console.error('Error fetching updated by user:', err)
    updatedByUser.value = 'Unknown User'
  }
}

watch(() => props.settings?.updated_by, () => {
  fetchUpdatedByUser()
}, { immediate: true })

function formatDateTime(dateString) {
  if (!dateString) return 'Never'
  const date = new Date(dateString)
  return date.toLocaleString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
    hour12: true
  })
}

onMounted(() => {
  fetchUpdatedByUser()
})
</script>

<template>
  <div class="card">
    <div class="px-6 py-4 border-b border-gray-200">
      <h3 class="text-lg font-semibold text-neutral-900">Audit Information</h3>
      <p class="text-sm text-gray-600 mt-1">Track changes to settings</p>
    </div>

    <div class="p-6 space-y-3">
      <!-- Last Updated -->
      <div>
        <label class="text-sm font-medium text-gray-700">Last Updated</label>
        <p class="mt-1 text-base text-gray-900">
          {{ formatDateTime(settings?.updated_at) }}
        </p>
      </div>

      <!-- Updated By -->
      <div v-if="settings?.updated_by">
        <label class="text-sm font-medium text-gray-700">Updated By</label>
        <p class="mt-1 text-base text-gray-900">
          {{ updatedByUser || 'Loading...' }}
        </p>
      </div>

      <!-- Created At -->
      <div>
        <label class="text-sm font-medium text-gray-700">Created</label>
        <p class="mt-1 text-base text-gray-900">
          {{ formatDateTime(settings?.created_at) }}
        </p>
      </div>
    </div>
  </div>
</template>
