{% if not var("enable_xero_accounting_source") %}
{{
    config(
        enabled=false
    )
}}
{% endif %}

WITH xero_contacts as (
  {{ filter_stitch_table(var('stg_xero_accounting_stitch_schema'),var('stg_xero_accounting_stitch_contacts_table'),'contactid') }}
),

contacts as (

  WITH phones as (SELECT contacts.contactid, phones.phonetype, phones.phonenumber, phones.phoneareacode, phones.phonecountrycode
    FROM xero_contacts contacts,
 unnest(phones) as phones
 ),
      addresses as (SELECT contacts.contactid, addresses.addresstype, addresses.addressline1, addresses.addressline2, addresses.addressline3, addresses.addressline4, addresses.city, addresses.region, addresses.country, addresses.postalcode
         FROM xero_contacts contacts,
 unnest(addresses) as addresses
 )
 select
        concat('{{ var('stg_xero_accounting_id-prefix') }}',contacts.contactid) as contact_id,
        contacts.firstname as contact_first_name,
        contacts.lastname as contact_last_name,
        cast(null as string) as contact_job_title,
        coalesce(concat(contacts.firstname,' ',contacts.lastname),contacts.emailaddress) as contact_name,
        contacts.emailaddress as contact_email,
        replace(concat(replace(defaultphone.phonecountrycode,'+','00'),defaultphone.phoneareacode,defaultphone.phonenumber),' ','') as contact_phone,
        replace(concat(replace(mobilephone.phonecountrycode,'+','00'),mobilephone.phoneareacode,mobilephone.phonenumber),' ','') as contact_mobile_phone,
        string_agg(distinct addresses.addressline1) as contact_address,
        string_agg(distinct addresses.city) as contact_city,
        string_agg(distinct addresses.region) as contact_state,
        string_agg(distinct addresses.country) as contact_country,
        string_agg(distinct addresses.postalcode) as contact_postcode_zip,
        cast(null as string) as contact_company,
        cast(null as string) as contact_website,
        cast(null as string) as contact_company_id,
        cast(null as string) as contact_owner_id,
        contacts.contactstatus as contact_lifecycle_stage,
        cast(null as boolean)         as user_is_contractor,
        cast(null as boolean) as user_is_staff,
        cast(null as int64)           as user_weekly_capacity,
        cast(null as int64)           as user_default_hourly_rate,
        cast(null as int64)           as user_cost_rate,
        false                          as user_is_active,
        cast(null as timestamp) as contact_created_date,
        contacts.updateddateutc as contact_last_modified_date
 from xero_contacts contacts
 left outer join addresses as addresses
 on contacts.contactid = addresses.contactid
 and addresses.addresstype = 'STREET'
 left outer join phones as mobilephone
 on contacts.contactid = mobilephone.contactid
 and mobilephone.phonetype = 'MOBILE'
 left outer join phones as defaultphone
 on contacts.contactid = defaultphone.contactid
 and mobilephone.phonetype = 'DEFAULT'
 where concat(contacts.firstname,' ',contacts.lastname) is not null
 group by 1,2,3,4,5,6,7,8,14,15,16,17,18,19,20,21,22,23,24,25,26
)

select * from contacts
