require 'net/http'
require 'fileutils'

# Let's download some PHP packages.

# Change these as needed.
version = "5.3.26"
arch = "x86_64"
format_string = "/pub/ius/stable/Redhat/6/%s/%s-%s-1.ius.el6.%s.rpm"

# Set up the directories needed.
script_path = File.expand_path(File.dirname(__FILE__))
download_directory = script_path + "/rpm-download"
extract_directory = script_path + "/rpm-extract"
[download_directory, extract_directory]. each { |dir|
  FileUtils.rm_rf(dir) if File.directory?(dir)
  FileUtils.mkdir(dir) unless File.directory?(dir)
}

# Clean out the directories.

# Ensure that the package is actually available for download from IUS.
# This can probably be done better with native repository tools. C'est la vie.
def check_package (url)
  Net::HTTP.start("dl.iuscommunity.org") do |http|
    http.open_timeout = 2
    http.read_timeout = 2
    http.head(url).code == "200"
  end
end

packages = [
  "php53u-cli",
  "php53u-mbstring",
  "php53u-devel",
  "php53u",
  "php53u-gd",
  "php53u-soap",
  "php53u-xml",
  "php53u-pdo",
  "php53u-mysql",
  "php53u-process",
  "php53u-common"
]

package_urls = packages.map { |p| format_string % [arch, p, version, arch] }.select { |p| check_package(p) }

# Download the packages that are not 404s.
Dir.chdir(download_directory)
package_urls.each { |url|
  system("wget http://dl.iuscommunity.org%s" % url)
}

# We have to chdir here, since cpio wants us to be in the directory where we will expand things.
Dir.chdir(extract_directory)
package_urls.each { |file|
  rpm_path = download_directory + "/" + file.split("/").last
  system("rpm2cpio %s | cpio -idv" % rpm_path)
}

