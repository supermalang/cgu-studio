// Single source of truth for the platforms the CMS supports. Values must match
// the social_platform enum in migration 009.
export const PLATFORMS = [
  { value: 'instagram', label: 'Instagram', color: '#E1306C', charLimit: 2200, maxMedia: 10 },
  { value: 'tiktok', label: 'TikTok', color: '#111118', charLimit: 2200, maxMedia: 1 },
  { value: 'linkedin', label: 'LinkedIn', color: '#0A66C2', charLimit: 3000, maxMedia: 9 },
  { value: 'facebook', label: 'Facebook', color: '#1877F2', charLimit: 63206, maxMedia: 10 },
  { value: 'x', label: 'X', color: '#111118', charLimit: 280, maxMedia: 4 },
  { value: 'youtube', label: 'YouTube', color: '#FF0000', charLimit: 5000, maxMedia: 1 },
  { value: 'threads', label: 'Threads', color: '#111118', charLimit: 500, maxMedia: 10 },
  { value: 'pinterest', label: 'Pinterest', color: '#E60023', charLimit: 500, maxMedia: 1 }
]

const BY_VALUE = Object.fromEntries(PLATFORMS.map(p => [p.value, p]))

export function getPlatform(value) {
  return BY_VALUE[value] || { value, label: value, color: '#8A8A94', charLimit: 2200, maxMedia: 10 }
}

// Caption length is the constraint users hit first, so surface it per channel
// rather than after a failed publish.
export function checkCaptionLength(platform, caption) {
  const { charLimit, label } = getPlatform(platform)
  const length = (caption || '').length
  return {
    length,
    charLimit,
    remaining: charLimit - length,
    exceeded: length > charLimit,
    message: length > charLimit ? `${length - charLimit} characters over the ${label} limit` : null
  }
}

export const POST_STATUSES = [
  { value: 'draft', label: 'Draft', class: 'bg-neutral-100 text-neutral-700' },
  { value: 'needs_review', label: 'Needs review', class: 'bg-warning-50 text-warning-700' },
  { value: 'approved', label: 'Approved', class: 'bg-primary-50 text-primary-700' },
  { value: 'scheduled', label: 'Scheduled', class: 'bg-primary-50 text-primary-700' },
  { value: 'publishing', label: 'Publishing', class: 'bg-warning-50 text-warning-700' },
  { value: 'published', label: 'Published', class: 'bg-success-50 text-success-700' },
  { value: 'failed', label: 'Failed', class: 'bg-error-50 text-error-700' },
  { value: 'archived', label: 'Archived', class: 'bg-neutral-100 text-neutral-500' }
]

const STATUS_BY_VALUE = Object.fromEntries(POST_STATUSES.map(s => [s.value, s]))

export function getStatus(value) {
  return STATUS_BY_VALUE[value] || { value, label: value, class: 'bg-neutral-100 text-neutral-700' }
}
