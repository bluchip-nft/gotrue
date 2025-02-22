-- this change is relatively temporary
-- it is meant to keep database consistency guarantees until there is proper
-- introduction of account linking / merging / delinking APIs, at which point
-- rows in the users table will allow duplicates but with programmatic control

alter table only {{ index .Options "Namespace" }}.users
  add column if not exists is_sso_user boolean not null default false;

comment on column {{ index .Options "Namespace" }}.users.is_sso_user is 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';

create unique index if not exists users_email_partial_key on {{ index .Options "Namespace" }}.users (email) where (is_sso_user = false);

comment on index {{ index .Options "Namespace" }}.users_email_partial_key is 'Auth: A partial unique index that applies only when is_sso_user is false';

DO $$
DECLARE
  alter table only {{ index .Options "Namespace" }}.users
    drop constraint if exists users_email_key;
EXCEPTION
  WHEN OTHERS THEN
    raise notice 'users_email_key does not exist';
END;
$$
    
