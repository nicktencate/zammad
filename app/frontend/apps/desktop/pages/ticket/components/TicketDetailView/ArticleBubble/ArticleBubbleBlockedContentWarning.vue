<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonIcon from '#shared/components/CommonIcon/CommonIcon.vue'
import type { TicketArticle } from '#shared/entities/ticket/types'

import { useEmailFileUrls } from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/useEmailFileUrls.ts'

interface Props {
  article: TicketArticle
}

const props = defineProps<Props>()

const { originalFormattingUrl } = useEmailFileUrls(props.article)
</script>

<template>
  <div
    v-if="article.preferences?.remote_content_removed"
    class="flex flex-row gap-1 p-3"
    role="alert"
  >
    <CommonIcon class="shrink-0" name="exclamation-triangle" size="small" />
    <CommonLabel class="block">
      {{
        i18n.t(
          'This message contains images or other content hosted by an external source. It was blocked, but you can download the original formatting.',
        )
      }}
      <br />
      <CommonLink
        v-if="originalFormattingUrl"
        :link="originalFormattingUrl"
        :rest-api="true"
        size="medium"
        target="_blank"
      >
        {{ i18n.t('Original Formatting') }}
      </CommonLink>
    </CommonLabel>
  </div>
</template>
