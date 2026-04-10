# frozen_string_literal: true

require "rails_helper"

# We make sure that the checksum of the file overriden is the same
# as the expected. If this test fails, it means that the overriden
# file should be updated to match any change/bug fix introduced in the core
checksums = [
  {
    package: "decidim-proposals",
    files: {
      "/app/views/decidim/proposals/admin/proposals/_proposal-tr.html.erb" => "608af89f7bfa800fe2e3c853f8e2ace0",
      "/app/views/decidim/proposals/admin/proposals/_proposals-thead.html.erb" => "24c74e018ea4ac719652dd4c5acd4a29"
    }
  },
  {
    package: "decidim-core",
    files: {
      "/app/views/layouts/decidim/header/_main.html.erb" => "a090eeca739613446d2eab8f4de513b1",
      "/app/views/layouts/decidim/footer/_mini.html.erb" => "c67cc97db27cdcf926f60682e399f688"
    }
  }
]

describe "Overriden files", type: :view do
  checksums.each do |item|
    spec = Gem::Specification.find_by_name(item[:package])
    item[:files].each do |file, signature|
      it "#{spec.gem_dir}#{file} matches checksum" do
        expect(md5("#{spec.gem_dir}#{file}")).to eq(signature)
      end
    end
  end

  private

  def md5(file)
    Digest::MD5.hexdigest(File.read(file))
  end
end
