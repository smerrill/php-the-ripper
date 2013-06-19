require 'net/http'
require 'fileutils'

# Let's download some PHP packages.

# Change these as needed.
version = "5.4.16"
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
  Net::HTTP.start('dl.iuscommunity.org') do |http|
    http.open_timeout = 2
    http.read_timeout = 2
    http.head(url).code == '200'
  end
end

packages = [
  'php54-cli',
  'php54-mbstring',
  'php54-devel',
  'php54',
  'php54-gd',
  'php54-soap',
  'php54-xml',
  'php54-pdo',
  'php54-mysql',
  'php54-process',
  'php54-common',
  'php54-fpm',
]

package_urls = packages.map { |p| format_string % [arch, p, version, arch] }.select { |p| check_package(p) }
package_urls = package_urls.map { |url| 'http://dl.iuscommunity.org%s' % url }

# Add extra packages that we have to have in the tarball.
package_urls.concat [
  'http://dl.iuscommunity.org/pub/ius/stable/Redhat/6/x86_64/php54-pear-1.9.4-2.ius.el6.noarch.rpm',
  'http://dl.iuscommunity.org/pub/ius/stable/Redhat/6/x86_64/php54-pecl-mongo-1.3.2-1.ius.el6.x86_64.rpm',
  'http://dl.iuscommunity.org/pub/ius/stable/Redhat/6/x86_64/php54-pecl-apc-3.1.13-1.ius.el6.x86_64.rpm',
  'http://mirrors.rit.edu/centos/6.4/os/x86_64/Packages/t1lib-5.1.2-6.el6_2.1.x86_64.rpm',
  'http://apt.sw.be/redhat/el6/en/x86_64/rpmforge/RPMS/mod_fastcgi-2.4.6-2.el6.rf.x86_64.rpm',
]

# Download the packages that are not 404s.
Dir.chdir(download_directory)
package_urls.each { |url|
  puts "Downloading #{url}."
  system('wget %s' % url)
}

# We have to chdir here, since cpio wants us to be in the directory where we will expand things.
Dir.chdir(extract_directory)
Dir.glob('%s/*.rpm' % download_directory).each { |file|
  rpm_path = download_directory + '/' + file.split('/').last
  system('rpm2cpio %s | cpio -idv' % rpm_path)
}

# Now, some OpenShifty cleanup.
# For one, we want the PHP cartridge's php.ini to win.
FileUtils.rm('%s/etc/php.ini' % extract_directory)
