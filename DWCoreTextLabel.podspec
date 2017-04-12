Pod::Spec.new do |s|
s.name = 'DWCoreTextLabel'
s.version = '1.0.3'
s.license = { :type => 'MIT', :file => 'LICENSE' }
s.summary = 'It's a Label based on coreText,help you to layout of the collocation of illustration and character.'
s.homepage = 'https://github.com/CodeWicky/DWCoreTextLabel'
s.authors = { 'codeWicky' => 'codewicky@163.com' }
s.social_media_url = 'http://www.jianshu.com/u/a56ec10f6603'
s.source = { :git => 'https://github.com/CodeWicky/DWCheckBox.git', :tag => s.version.to_s }
s.requires_arc = true
s.ios.deployment_target = '7.0'
s.source_files = 'DWCheckBox/**/*.{h,m}'
s.resource = 'DWCheckBox/DWCheckBoxBundle.bundle'
s.frameworks = 'UIKit'
end
