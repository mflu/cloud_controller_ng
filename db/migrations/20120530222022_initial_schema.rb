# Copyright (c) 2009-2012 VMware, Inc.

Sequel.migration do
  change do
    create_table :users do
      VCAP::Migration.common(self)

      Boolean :admin,  :default => false
      Boolean :active, :default => false
    end

    create_table :organizations do
      VCAP::Migration.common(self)
      String :name, :null => false, :index => true, :unique => true
    end

    # Organization permissions
    [:users, :managers, :billing_managers, :auditors].each do |perm|
      VCAP::Migration.create_permission_table(self, :organization, perm)
    end

    create_table :domains do
      VCAP::Migration.common(self)

      String :name, :null => false, :unique => true
      foreign_key :organization_id, :organizations, :null => false
    end

    create_table :spaces do
      VCAP::Migration.common(self)

      String :name, :null => false

      foreign_key :organization_id, :organizations, :null => false
      index [:organization_id, :name], :unique => true
    end

    alter_table :users do
      add_foreign_key :default_space_id, :spaces
    end

    create_table :domains_spaces do
      foreign_key :space_id, :spaces, :null => false
      foreign_key :domain_id, :domains, :null => false

      index [:space_id, :domain_id], :unique => true
    end

    # App Space permissions
    [:developers, :managers, :auditors].each do |perm|
      VCAP::Migration.create_permission_table(self, :space, perm)
    end

    create_table :service_auth_tokens do
      VCAP::Migration.common(self)

      String :label,         :null => false
      String :provider,      :null => false
      String :crypted_token, :null => false

      index [:label, :provider], :unique => true
    end

    create_table :services do
      VCAP::Migration.common(self)

      String :label,       :null => false, :index => true
      String :provider,    :null => false
      String :url,         :null => false
      String :description, :null => false
      String :version,     :null => false

      String  :info_url
      String  :acls
      Integer :timeout
      Boolean :active, :default => false

      index [:label, :provider], :unique => true
    end

    create_table :service_plans do
      VCAP::Migration.common(self)

      String :name,        :null => false
      String :description, :null => false

      foreign_key :service_id, :services, :null => false
      index [:service_id, :name], :unique => true
    end

    create_table :service_instances do
      VCAP::Migration.common(self)

      String :name, :null => false, :index => true

      # the creds are needed for bacwkards compatability, but,
      # they should be deprecated in place of bindings only
      String :credentials, :null => false
      String :vendor_data

      foreign_key :space_id,        :spaces,            :null => false
      foreign_key :service_plan_id, :service_plans,     :null => false

      index [:space_id, :name], :unique => true
    end

    create_table :runtimes do
      VCAP::Migration.common(self)

      String :name,        :null => false
      String :description, :null => false

      index :name, :unique => true
    end

    create_table :frameworks do
      VCAP::Migration.common(self)

      String :name,        :null => false
      String :description, :null => false

      index :name, :unique => true
    end

    create_table :routes do
      VCAP::Migration.common(self)

      # TODO: this is semi temporary and will be fully thought through when
      # we do custom domains.  For now, this "works" and will prevent
      # collisions.
      String :host, :null => false
      foreign_key :domain_id, :domains, :null => false
      index [:host, :domain_id], :unique => true
    end

    create_table :apps do
      VCAP::Migration.common(self)

      String :name, :null => false

      # Do the bare miminum for now.  We'll migrate this to something
      # fancier later if we need it.
      Boolean :production, :default => false

      # environment provided by the developer.
      # does not include environment from service
      # bindings.  those get merged from the bound
      # services
      String :environment_json

      # quota settings
      #
      # FIXME: these defaults are going to move out of here and into
      # the upper layers so that they are more easily run-time configurable
      #
      # This *MUST* be moved because we have to know up at the controller
      # what the actual numbers are going to be so that we can
      # send the correct billing events to the "money maker"
      Integer :memory,           :default => 256
      Integer :instances,        :default => 0
      Integer :file_descriptors, :default => 256
      Integer :disk_quota,       :default => 2048

      # app state
      # TODO: this is a place holder
      String :state,             :null => false, :default => "STOPPED"

      # package state
      # TODO: this is a place holder
      String :package_state,     :null => false, :default => "PENDING"
      String :package_hash

      # TODO: sort out the legacy cc fields of metadata and run_count

      foreign_key :space_id,     :spaces,     :null => false
      foreign_key :runtime_id,   :runtimes,   :null => false
      foreign_key :framework_id, :frameworks, :null => false

      index [:space_id, :name], :unique => true
    end

    create_table :apps_routes do
      foreign_key :app_id, :apps, :null => false
      foreign_key :route_id, :routes, :null => false
      index [:app_id, :route_id], :unique => true
    end

    create_table(:service_bindings) do
      VCAP::Migration.common(self)

      String :credentials, :null => false
      String :binding_options
      String :vendor_data

      foreign_key :app_id, :apps, :null => false
      foreign_key :service_instance_id, :service_instances, :null => false
      index [:app_id, :service_instance_id], :unique => true
    end
  end
end
