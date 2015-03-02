
##
# Slothbot::Wheel

module Slothbot
	class Wheel
		class Punishment
			def initialize(text, severity=:average)
				@severity = severity
				@text = text
			end

			attr_accessor :severity

			def to_s
				@text
			end
		end

		class GulagPunishment < Punishment
			def initialize(text)
				super
				srand
				resentence
			end

			def to_s
				string = @text.sub '$years', @years.to_s
				resentence
				return string
			end

			private

			def resentence
				@years = rand(1..1000000) - 1
				@severity = [:low, :average, :high][@years / 333334]
			end
		end

		def add_punishment(punishment)
			@punishments << punishment
		end

		def delete_punishment(punishment)
			@punishments.delete(punishment)
		end

		def initialize
			@punishments = [
				Punishment.new("death by the crazy 88s", severity=:high),
				Punishment.new("death by surprise jihad", severity=:high),
				Punishment.new("death by cantrymen", severity=:high),
				GulagPunishment.new("gulag $years years"),
			]
		end

		def spin(severity=nil)
			if severity.nil?
				set = @punishments
			else
				set = @punishments.collect do |punishment|
					punishment if punishment.severity == severity
				end
			end
			srand
			sentence = set[rand(set.length)].to_s
			sentence.empty? ? "wheel has no words" : sentence
		end
	end
end
