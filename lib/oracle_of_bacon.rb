require 'byebug'                # optional, may be helpful
require 'open-uri'              # allows open('http://...') to return body
require 'cgi'                   # for escaping URIs
require 'nokogiri'              # XML parser
require 'active_model'          # for validations

class OracleOfBacon

	class InvalidError < RuntimeError ; end
	class NetworkError < RuntimeError ; end
	class InvalidKeyError < RuntimeError ; end

	attr_accessor :from, :to
	attr_reader :api_key, :response, :uri

	include ActiveModel::Validations
	validates_presence_of :from
	validates_presence_of :to
	validates_presence_of :api_key
	validate :from_does_not_equal_to

	def from_does_not_equal_to
		if @to == @from
			self.errors[:base] << "From cannot be the same as To"
		end
	end

	def initialize(api_key='38b99ce9ec87')
		@api_key = api_key
		@to = 'Kevin Bacon'
		@from = 'Kevin Bacon'
	end

	def find_connections
		make_uri_from_arguments
		begin
			xml = URI.parse(uri).read
		rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
			Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
			Net::ProtocolError => e
			# convert all of these into a generic OracleOfBacon::NetworkError,
			#  but keep the original error message
			# your code here
			raise OracleOfBacon::NetworkError
		end
		# your code here: create the OracleOfBacon::Response object
		OracleOfBacon::Response.new(xml)
	end

	def make_uri_from_arguments
		# your code here: set the @uri attribute to properly-escaped URI
		#   constructed from the @from, @to, @api_key arguments
		@uri = 'http://oracleofbacon.org/cgi-bin/xml?' + [(!@api_key.nil? ? "p=" + URI.escape(@api_key).gsub('%20', '+') : ''), (@from ? "a=" + URI.escape(@from).gsub('%20', '+') : ''), (@to ? "b=" + URI.escape(@to).gsub('%20', '+') : '')].join('&')

	end

	class Response
		attr_reader :type, :data
		# create a Response object from a string of XML markup.
		def initialize(xml)
			@doc = Nokogiri::XML(xml)
			parse_response
		end

		private

		def parse_response
			puts @doc.xpath
			if ! @doc.xpath('/error').empty?
				parse_error_response
			elsif ! @doc.xpath('/link').empty?
				parse_graph_response
			elsif ! @doc.xpath('/spellcheck').empty?
				parse_spellcheck_response
			else
				parse_unknown_response
			end
		end

		def parse_error_response
			@type = :error
			@data = 'Unauthorized access'
		end

		def parse_graph_response
			@type = :graph
			@data = @doc.xpath('/link/*').children.map{|el| el.content}
		end

		def parse_spellcheck_response
			@type = :spellcheck
			@data = @doc.xpath('/spellcheck/match').children.map{|el| el.content}
		end

		def parse_unknown_response
			@type = :unknown
			@data = 'unknown response'
		end
	end
end

