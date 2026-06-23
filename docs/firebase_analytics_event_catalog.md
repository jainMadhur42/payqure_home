# Payqure Home Analytics Catalog

All Firebase Analytics calls go through `AppAnalytics`. Event payloads must not
contain names, email addresses, phone numbers, provider names, addresses, or
free-form notes.

## Lifecycle And Authentication

| Event | Parameters |
| --- | --- |
| `app_opened` | `app_version`, `platform` |
| `signup_started` | `method`, `source` |
| `signup_completed` | `method`, `source` |
| `login_started` | `method`, `source` |
| `login_completed` | `method`, `source` |
| `logout_clicked` | `source` |
| `password_reset_started` | `method`, `source` |
| `password_reset_completed` | `method`, `source` |

## Onboarding

| Event | Parameters |
| --- | --- |
| `onboarding_started` | none |
| `onboarding_screen_viewed` | `screen_index`, `screen_name` |
| `onboarding_skipped` | `screen_index`, `screen_name` |
| `onboarding_completed` | none |

## Services And Entries

| Event | Parameters |
| --- | --- |
| `add_service_started` | `source` |
| `service_template_selected` | service context |
| `service_created` | service context, `has_reminder`, `has_contact_number`, `source` |
| `service_creation_failed` | service context, `error_type`, `source` |
| `service_updated` | service context |
| `service_deleted` | service context |
| `daily_entry_started` | service context, `source`, `date_relation` |
| `daily_entry_logged` | service and entry context |
| `daily_entry_updated` | service and entry context |
| `daily_entry_deleted` | service and entry context |
| `entry_log_failed` | service context, `operation`, `error_type` |
| `future_entry_blocked` | service context, `source`, `date_relation`, `month_offset` |

Service context includes generic fields such as `service_type`,
`service_nature`, `unit_type`, and pricing buckets. Exact financial amounts are
not sent. Entry context includes
`entry_status`, `quantity_bucket`, `date_relation`, and change flags. It never
contains service names entered by users or entry notes.

## Quick Log And Calendar

| Event | Parameters |
| --- | --- |
| `quick_log_opened` | `source`, date context |
| `quick_log_entry_logged` | entry context, `total_services`, `logged_count`, `pending_count` |
| `quick_log_completed` | `total_services`, `logged_count`, `pending_count` |
| `calendar_opened` | service context |
| `calendar_date_selected` | service context, `date_relation`, `month_offset` |
| `calendar_month_changed` | `month_offset`, `source` |

## Payments And Documents

| Event | Parameters |
| --- | --- |
| `payment_screen_opened` | service context, `source` |
| `payment_record_started` | service context, `payment_type`, `source` |
| `payment_recorded` | service context, `payment_mode`, `payment_result`, `amount_bucket`, `source` |
| `payment_record_failed` | service context, `operation`, `error_type`, `source` |
| `payment_updated` | payment context |
| `payment_deleted` | payment context |
| `credit_added` | service context, `payment_type`, `amount_bucket` |
| `payment_history_opened` | optional service context, `source` |
| `billing_summary_opened` | service context, `source` |
| `pdf_generation_started` | service context, `month_offset`, `source` |
| `pdf_generated` | service context, `month_offset`, `source` |
| `pdf_generation_failed` | service context, `month_offset`, `source` |
| `pdf_shared` | service context, `month_offset`, `source` |

## Contacts, Settings, And Legal

| Event | Parameters |
| --- | --- |
| `contacts_opened` | none |
| `provider_call_clicked` | service context, `source` |
| `provider_contact_copied` | service context, `source` |
| `more_tab_opened` | none |
| `profile_opened` | none |
| `privacy_policy_opened` | none |
| `terms_opened` | none |
| `delete_account_opened` | none |
| `delete_account_requested` | `source` |

## Sync And Reliability

| Event | Parameters |
| --- | --- |
| `offline_mode_detected` | `entity_type` |
| `sync_started` | optional `entity_type` |
| `sync_completed` | optional `entity_type`, `pending_count` |
| `sync_failed` | `entity_type`, sanitized `error_type` |
| `local_change_pending` | `entity_type`, `pending_count` |

Non-fatal PDF, sync, database, and compatibility failures are also recorded in
Crashlytics with controlled context keys. Analytics events never include raw
exception messages.

## Screen Views

Major routes emit Firebase `screen_view`, including onboarding, login, signup,
Home, Add Service, Service Detail, Quick Log, Add Entry, Billing Summary,
Payment History, PDF Preview, Contacts, More, Profile, and legal screens.

## User Properties

Only aggregate, non-sensitive properties are used:

- `service_count`
- `service_count_bucket`
- `has_created_service`
- `has_quantity_service`
- `has_attendance_service`
- `has_fixed_monthly_service`
- `has_logged_entry`
- `has_recorded_payment`
- `preferred_service_type`
- `currency_code`
- `country_code`
- `app_language`
- `signup_method`
- `app_version`

Firebase calculates DAU, WAU, and MAU from active users and `app_opened`; no
personal identifier is set as an Analytics user property.
