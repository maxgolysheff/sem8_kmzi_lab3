require 'openssl'

def decrypt_data(key)
  cipher = OpenSSL::Cipher.new('AES-128-ECB')

  cipher.decrypt
  cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(key, SALT, ITERATIONS, 16)

  decrypted = cipher.update(DATA_TO_DECRYPT) + cipher.final
  decrypted if decrypted.include?('End data.')
rescue OpenSSL::Cipher::CipherError
  nil
end

file_data = File.read('task3', binmode: true)

PASSWORD = 'aiJCdXt73Xbh2FMb'.freeze
PASSWORD_SIZE = 9.freeze

SALT = file_data[0, 4].freeze
ITERATIONS = file_data[7].unpack1('C').freeze
DATA_TO_DECRYPT = file_data[12..].freeze
PASSWORD_ARRAY = PASSWORD.chars.freeze
THREAD_NUMBER = `nproc`.to_i.freeze

puts "Salt: #{SALT}, Iterations: #{ITERATIONS}, thread number: #{THREAD_NUMBER}"

work = PASSWORD_ARRAY.combination(PASSWORD_SIZE).to_a

total_work = work.size

work.each_slice((total_work.to_f / THREAD_NUMBER).ceil).with_index do |slice, index|
  Process.fork do
    puts "Thread #{index} started"
    puts "Slice size: #{slice.size}"

    slice.each do |key|
      key.permutation(PASSWORD_SIZE).each do |permutated_key|
        decrypted_data = decrypt_data(permutated_key.join)

        if decrypted_data
          puts "Decrypted data: #{decrypted_data}"
          exit(0)
        end
      end
    end
  end
end

Process.wait
