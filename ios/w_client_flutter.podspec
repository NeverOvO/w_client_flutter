#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint w_client_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'w_client_flutter'
  s.version          = '1.0.0'
  s.summary          = '国家网络身份认证Flutter-NeverOuO'
  s.description      = <<-DESC
国家网络身份认证Flutter
                       DESC
  s.homepage         = 'https://github.com/NeverOvO/w_client_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'NeverOuO' => '1019832705@qq.com' }
  s.source           = { :path => '.' }

  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # 源码文件：插件 + SDK
  s.source_files       = 'Classes/**/*.h', 'Classes/**/*.m'
  s.public_header_files= 'Classes/**/*.h'

  # 链接系统库
  s.frameworks         = 'UIKit'
  s.requires_arc       = true
end
