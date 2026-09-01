<script setup>
import { ref, computed } from 'vue'
import { usePostsStore } from '@/stores/posts'
import { useToast } from '@/composables/useToast'
import { getPlatform, getStatus, checkCaptionLength } from '@/lib/platforms'

const props = defineProps({
  post: { type: Object, required: true },
  // The parent post caption, used whenever a channel has no override.
  baseBody: { type: String, default: '' }
})

const postsStore = usePostsStore()
const { showToast } = useToast()

const openVariantId = ref(null)
// Local edits, keyed by variant id, so typing in one channel doesn't refetch.
const edits = ref({})
const savingId = ref(null)

const variants = computed(() =>
  [...(props.post.post_variants || [])].sort((a, b) =>
    (a.social_accounts?.platform || '').localeCompare(b.social_accounts?.platform || '')
  )
)

function effectiveBody(variant) {
  if (variant.id in edits.value) return edits.value[variant.id]
  return variant.body_override ?? props.baseBody
}

function isOverridden(variant) {
  return variant.body_override !== null && variant.body_override !== undefined
}

function lengthCheck(variant) {
  return checkCaptionLength(variant.social_accounts?.platform, effectiveBody(variant))
}

function toggle(variantId) {
  openVariantId.value = openVariantId.value === variantId ? null : variantId
}

async function saveOverride(variant) {
  savingId.value = variant.id

  try {
    const body = edits.value[variant.id]
    await postsStore.updateVariant(variant.id, { body_override: body })
    delete edits.value[variant.id]
    showToast(`${getPlatform(variant.social_accounts?.platform).label} caption saved.`, 'success')
  } catch (err) {
    console.error('Error saving variant:', err)
    showToast(`Could not save this channel: ${err.message}`, 'error')
  } finally {
    savingId.value = null
  }
}

// Clearing the override makes the channel fall back to the post caption again.
async function resetToBase(variant) {
  savingId.value = variant.id

  try {
    await postsStore.updateVariant(variant.id, { body_override: null })
    delete edits.value[variant.id]
    showToast('Reverted to the shared caption.', 'success')
  } catch (err) {
    showToast(`Could not reset this channel: ${err.message}`, 'error')
  } finally {
    savingId.value = null
  }
}
</script>

<template>
  <div class="card p-6">
    <h2 class="font-bold text-neutral-900 mb-1">Per-channel captions</h2>
    <p class="text-xs text-neutral-500 mb-4">
      Each channel starts from the shared caption. Edit one to tailor it.
    </p>

    <div v-for="variant in variants" :key="variant.id" class="border-t border-neutral-100 py-3 first:border-t-0">
      <button @click="toggle(variant.id)" class="w-full flex items-center gap-3 text-left">
        <span
          class="w-2.5 h-2.5 rounded-full shrink-0"
          :style="{ backgroundColor: getPlatform(variant.social_accounts?.platform).color }"
        />
        <span class="text-sm font-semibold text-neutral-900">
          {{ getPlatform(variant.social_accounts?.platform).label }}
        </span>
        <span class="text-sm text-neutral-500 truncate">{{ variant.social_accounts?.handle }}</span>

        <span
          v-if="isOverridden(variant)"
          class="text-[10px] px-1.5 py-0.5 rounded-full bg-primary-50 text-primary-700 font-medium"
        >
          Custom
        </span>

        <span
          class="ml-auto text-[10px] px-1.5 py-0.5 rounded-full font-medium"
          :class="getStatus(variant.status).class"
        >
          {{ getStatus(variant.status).label }}
        </span>

        <span
          class="text-xs tabular-nums"
          :class="lengthCheck(variant).exceeded ? 'text-error-600 font-semibold' : 'text-neutral-400'"
        >
          {{ lengthCheck(variant).length }}/{{ lengthCheck(variant).charLimit }}
        </span>
      </button>

      <!-- Publish failure surfaced inline, where the retry decision is made -->
      <p v-if="variant.error_message" class="mt-2 text-xs text-error-600">
        Failed: {{ variant.error_message }}
      </p>
      <a
        v-if="variant.external_url"
        :href="variant.external_url"
        target="_blank"
        rel="noopener noreferrer"
        class="mt-2 inline-block text-xs text-primary-600 hover:underline"
      >
        View published post ↗
      </a>

      <div v-if="openVariantId === variant.id" class="mt-3">
        <textarea
          :value="effectiveBody(variant)"
          @input="edits[variant.id] = $event.target.value"
          rows="5"
          class="input-field text-sm"
          :placeholder="`Caption for ${getPlatform(variant.social_accounts?.platform).label}`"
        />
        <p v-if="lengthCheck(variant).exceeded" class="text-xs text-error-600 mt-1">
          {{ lengthCheck(variant).message }}
        </p>

        <div class="flex items-center gap-2 mt-2">
          <button
            @click="saveOverride(variant)"
            :disabled="!(variant.id in edits) || savingId === variant.id"
            class="btn-secondary text-sm"
          >
            {{ savingId === variant.id ? 'Saving…' : 'Save for this channel' }}
          </button>
          <button
            v-if="isOverridden(variant)"
            @click="resetToBase(variant)"
            :disabled="savingId === variant.id"
            class="btn-ghost text-sm"
          >
            Use shared caption
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
