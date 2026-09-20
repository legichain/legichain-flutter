Pod::Spec.new do |s|
  s.name = 'legichain_sdk'
  s.version = '2.0.0'
  s.summary = 'Native Legichain KYC capture, NFC and guided liveness.'
  s.homepage = 'https://legichain.com'
  s.license = { :type => 'MIT', :file => '../LICENSE' }
  s.author = { 'Legichain' => 'contact@legichain.com' }
  s.source = { :path => '.' }
  s.source_files = 'Classes/**/*.swift'
  s.dependency 'Flutter'
  s.dependency 'NFCPassportReader', '2.3.1'
  s.platform = :ios, '15.0'
  s.swift_version = '5.9'
  s.frameworks = 'AVFoundation', 'CoreNFC', 'Vision', 'UIKit'
end
