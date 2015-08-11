require 'minitest_helper'

module Sidekiq
  module Statistic
    describe 'Realtime' do
      before { Sidekiq.redis(&:flushdb) }

      let(:realtime){ Sidekiq::Statistic::Realtime.new }
      let(:current_time){ Time.new(2015, 8, 11, 23, 22, 21).utc }

      describe '::charts_initializer' do
        describe 'before any jobs' do
          it 'returns initialize array for realtime chart' do
            Time.stub :now, current_time do
              initialize_array = Sidekiq::Statistic::Realtime.charts_initializer
              assert_equal [['x', '20:22:21', '20:22:20', '20:22:19', '20:22:18', '20:22:17', '20:22:16', '20:22:15', '20:22:14', '20:22:13', '20:22:12', '20:22:11', '20:22:10']], initialize_array
            end
          end
        end

        describe 'after job' do
          it 'returns initialize array for realtime chart' do
            middlewared {}

            Time.stub :now, current_time do
              initialize_array = Sidekiq::Statistic::Realtime.charts_initializer
              assert_equal [['HistoryWorker', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], ['x', '20:22:21', '20:22:20', '20:22:19', '20:22:18', '20:22:17', '20:22:16', '20:22:15', '20:22:14', '20:22:13', '20:22:12', '20:22:11', '20:22:10']], initialize_array
            end
          end
        end
      end

      describe '#realtime_hash' do
        describe 'before any jobs' do
          it 'returns empty hash' do
            assert_equal({}, realtime.realtime_hash)
          end
        end

        describe 'after job' do
          it 'returns worker run count' do
            Time.stub :now, (current_time - 1) do
              middlewared {}

              begin
                middlewared do
                  raise StandardError.new('failed')
                end
              rescue
              end
            end

            Time.stub :now, current_time do
              assert_equal({'passed'=>{'HistoryWorker'=>1}, 'failed'=>{'HistoryWorker'=>1}}, realtime.realtime_hash)
            end
          end
        end
      end

      describe '#statistic' do
        describe 'before any jobs' do
          it 'returns hash with empty values' do
            Time.stub :now, current_time do
              assert_equal({failed: {columns: [['x', '20:22:21']]}, passed: {columns: [['x', '20:22:21']]}}, realtime.statistic)
            end
          end
        end

        describe 'after job' do
          it 'returns worker run count for each realtime chart' do
            Time.stub :now, (current_time - 1) do
              middlewared {}

              begin
                middlewared do
                  raise StandardError.new('failed')
                end
              rescue
              end
            end

            Time.stub :now, current_time do
              assert_equal({failed: {columns: [['HistoryWorker', 1], ['x', '20:22:21']]}, passed: {columns: [['HistoryWorker', 1], ['x', '20:22:21']]}}, realtime.statistic)
            end
          end
        end
      end
    end
  end
end
