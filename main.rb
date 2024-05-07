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

PASSWORD = 'irQjQCthOQZ5y277'.freeze
PASSWORD_SIZE = 9.freeze

SALT = file_data[0, 4].freeze
ITERATIONS = file_data[7].unpack1('C').freeze
DATA_TO_DECRYPT = file_data[12..].freeze
PASSWORD_ARRAY = PASSWORD.chars.freeze
THREAD_NUMBER = `nproc`.to_i.freeze

puts "Salt: #{SALT}, Iterations: #{ITERATIONS}, thread number: #{THREAD_NUMBER}"

work = PASSWORD_ARRAY.combination(PASSWORD_SIZE).to_a

total_work = work.size

threads = []

work.each_slice((total_work.to_f / THREAD_NUMBER).ceil).with_index do |slice, index|
  threads << Process.fork do
    puts "Thread #{index} started"
    puts "Slice size: #{slice.size}"

    last_time = Time.now

    slice.each.with_index do |key, i|
      if index == 0
        time_now = Time.now
        eta = (time_now - last_time) * (slice.size - i)
        puts "#{i}/#{slice.size}, ETA: #{eta.round}s (#{( eta / 60 ).round(2)}m), #{(i.to_f / slice.size * 100).round(2)}%"
      end

      key.permutation(PASSWORD_SIZE).each do |permutated_key|
        decrypted_data = decrypt_data(permutated_key.join)

        if decrypted_data
          puts "-" * 50
          puts "Decrypted data: #{decrypted_data}"
          puts "-" * 50
          exit(0)
        end
      end

      last_time = time_now if index == 0
    end
  end
end

Process.wait

threads.each do |thread|
  Process.kill('KILL', thread) 
rescue Errno::ESRCH
  nil
end
