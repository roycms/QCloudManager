Pod::Spec.new do |s|
  s.name         = 'QCloudManager'
  s.version      = "0.1.0"
  s.summary      = "QCloudManager"

  s.homepage     = "https://github.com/roycms/QCloudManager.git"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author       = { "roycms" => "roycms@qq.com" }

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/roycms/QCloudManager.git", :tag => s.version.to_s }

  s.source_files  = "*.*"

  s.requires_arc = true

end
