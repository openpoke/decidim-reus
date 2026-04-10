# frozen_string_literal: true

# This migration comes from decidim_assemblies (originally 20180124083729)
# This file has been modified by `decidim upgrade:migrations` task on 2026-03-16 12:44:40 UTC
class AddPrivateToAssemblies < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_assemblies, :private_space, :boolean, default: false
  end
end
