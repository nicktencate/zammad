// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import { useEmailFileUrls } from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/useEmailFileUrls.ts'

vi.mock('#desktop/pages/ticket/composables/useTicketInformation.ts', () => ({
  useTicketInformation: () => ({
    ticket: ref(createDummyTicket()),
  }),
}))

describe('useEmailFileUrls', () => {
  it('should return originalFormattingUrl and rawMessageUrl', () => {
    const { originalFormattingUrl, rawMessageUrl } = useEmailFileUrls(
      ref(
        createDummyArticle({
          attachmentsWithoutInline: [
            {
              preferences: {
                'original-format': true,
              },
              internalId: 123,
              name: 'test.txt',
            },
          ],
        }) as TicketArticle,
      ),
    )

    expect(originalFormattingUrl.value).toBe(
      '/ticket_attachment/1/1/123?disposition=attachment',
    )
    expect(rawMessageUrl.value).toBe('/api/v1/ticket_article_plain/1')
  })
})
