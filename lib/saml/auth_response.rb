module SAML
  class AuthResponse

    attr_accessor :request, :document, :logger
    include Onelogin::Saml::Codeing

    def initialize(request, logger = nil)
      raise ArgumentError.new("Response cannot be nil") if request.nil?
      self.logger = logger || ActiveRecord::Base.logger
      self.request = inflate(decode(request))
      self.document = Nokogiri::XML(self.request)
    end

    def get_sp_response_to
      document.xpath("//samlp:AuthnRequest").first["ID"]
    end

    def get_sp_destination
      Settings.sso.sp_destination
    end

    def get_idp_issuer
      Settings.host
    end

#    def get_sp_audience
#      Settings.sso.sp_audience
#    end


#
    def xml_time_format time
      time.strftime("%Y-%m-%dT%H:%M:%SZ")
    end


    def response_url(name_id, params={})
      prepared_result = create(name_id)
      base64_request = encode(prepared_result)
#      deflated_request = deflate(create(name_id))
#      base64_request = encode(deflated_request)
      base64_request.gsub!(/\s/,"")
#      encoded_response = escape(base64_request)
#
#      encoded_response
##      request_params = "?SAMLResponse=" + encoded_response
#
#      params.each_pair do |key, value|
#        request_params << "&#{key}=#{escape(value.to_s)}"
#      end
#      Settings.sso.sp_destination+ request_params
    end

    def create(name_id)
      time_line = Time.now.utc
      request_id = UUID.new.generate
      assert_id = UUID.new.generate

      time = xml_time_format(time_line)
      assertion = build_assertion_content(name_id, assert_id, time_line)

#      assertion_parsed = Nokogiri::XML(assertion)
#      assertion_parsed.xpath("//saml:Assertion//saml:Issuer").first.add_next_sibling(make_signature(assertion, assert_id))

      response = Builder::XmlMarkup.new
      response.tag!('samlp:Response', {"xmlns:samlp" => "urn:oasis:names:tc:SAML:2.0:protocol",
                                       "xmlns:saml" => "urn:oasis:names:tc:SAML:2.0:assertion",
                                       "xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#",
                                       "ID" => request_id,
                                       "Version" => "2.0",
                                       "InResponseTo" => get_sp_response_to,
                                       "IssueInstant" => time,
                                       "Destination" => get_sp_destination}) do
        response.tag!("saml:Issuer", get_idp_issuer)
        response.tag!("samlp:Status") do
          response.tag!("samlp:StatusCode", "Value" => "urn:oasis:names:tc:SAML:2.0:status:Success")
        end
        response << build_assertion_content(name_id, assert_id, time_line, make_signature(assertion, assert_id))
        #todo if insert node this way - need to canonicalize. nokogiri 1.4.4 has no possibility to do it. only it's branch can do it:(
#        response << assertion_parsed.xpath("//saml:Assertion").canonicalize.to_s
      end
      response.target!
    end


    def build_assertion_content(name_id, assert_id, time_line, sign =nil)
      time_and_ten = xml_time_format(time_line + 10.minutes)
      time = xml_time_format(time_line)

      xml = Builder::XmlMarkup.new

      xml.tag!('saml:Assertion', {"xmlns:saml"=>"urn:oasis:names:tc:SAML:2.0:assertion", "ID"=>assert_id, "Version"=>"2.0", "IssueInstant"=> time}) do
        xml.tag!("saml:Issuer", get_idp_issuer)

        xml << sign if sign.present?

        xml.tag! "saml:Subject" do
          xml.tag!("saml:NameID", {"Format"=>"urn:oasis:names:tc:SAML:2.0:nameid-format:transient"}, name_id)
          xml.tag!("saml:SubjectConfirmation", {"Method" => "urn:oasis:names:tc:SAML:2.0:cm:bearer"}) do
            xml.tag!("saml:SubjectConfirmationData", {"InResponseTo" => get_sp_response_to, "Recipient" => get_sp_destination, "NotOnOrAfter" => time_and_ten})
          end
        end

#        xml.tag!("saml:Conditions", {"NotBefore" => time, "NotOnOrAfter" => time_and_ten}) do
#          xml.tag!("saml:AudienceRestriction") do
#            xml.tag!("saml:Audience", get_sp_audience)
#          end
#        end

        xml.tag!("saml:AuthnStatement", {"AuthnInstant" => time, "SessionIndex" => assert_id}) do
          xml.tag!("saml:AuthnContext") do
            xml.tag!("saml:AuthnContextClassRef", "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport")
          end
        end
      end
      xml.target!
    end

    def make_signature(assertion, assert_id)
      certificate = File.read("#{Rails.root}/config/cert/#{Rails.env}/idp.ignite.com.crt")
#      certificate = File.read("#{Rails.root}/config/cert/development/IdpCertificate.cer")
      certificate.gsub!("-----BEGIN CERTIFICATE-----", "")
      certificate.gsub!("-----END CERTIFICATE-----", "")

      sign_info_xml_builder = Builder::XmlMarkup.new
      sign_info_xml_builder.tag!("ds:SignedInfo", {"xmlns:ds"=>"http://www.w3.org/2000/09/xmldsig#"}) do
        sign_info_xml_builder.tag!("ds:CanonicalizationMethod", {"Algorithm"=>"http://www.w3.org/2001/10/xml-exc-c14n#"})
        sign_info_xml_builder.tag!("ds:SignatureMethod", {"Algorithm"=>"http://www.w3.org/2000/09/xmldsig#rsa-sha1"})
        sign_info_xml_builder.tag!("ds:Reference", {"URI" => "##{assert_id}"}) do
          sign_info_xml_builder.tag!("ds:Transforms") do
            sign_info_xml_builder.tag!("ds:Transform", {"Algorithm"=>"http://www.w3.org/2000/09/xmldsig#enveloped-signature"})
            sign_info_xml_builder.tag!("ds:Transform", {"Algorithm"=>"http://www.w3.org/2001/10/xml-exc-c14n#"})
          end
          sign_info_xml_builder.tag!("ds:DigestMethod", {"Algorithm"=>"http://www.w3.org/2000/09/xmldsig#sha1"})
          sign_info_xml_builder.tag!("ds:DigestValue", {"URI" => assert_id}, signature_digest_value(assertion))
        end
      end
      sign_info_xml = sign_info_xml_builder.target!
      s_value = signature_sign_value(sign_info_xml)
      xml = Builder::XmlMarkup.new
      xml.tag!('ds:Signature', {"xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#"}) do
        xml << sign_info_xml
        xml.tag!("ds:SignatureValue", {"xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#"}, s_value)
        xml.tag!('ds:KeyInfo') do
          xml.tag!('ds:X509Data') do
            xml.tag!('ds:X509Certificate', certificate)
          end
        end
      end
      xml.target!
    end


    def signature_sign_value(xml)
      document = XMLSecurity::SignedDocument.new(xml)
      canoner = XML::Util::XmlCanonicalizer.new(false, true)
      signed_info_element = REXML::XPath.first(document, "//ds:SignedInfo", {"ds"=>"http://www.w3.org/2000/09/xmldsig#"})
      canon_string = canoner.canonicalize(signed_info_element)
#      private_key = OpenSSL::PKey::RSA.new(File.read("#{Rails.root}/config/cert/#{Rails.env}/idp.ignite.com.key"))
      #private_key = OpenSSL::PKey::RSA.new(File.read("#{Rails.root}/config/cert/development/SPkey.key"))
      private_key = OpenSSL::PKey::RSA.new(File.read("#{Rails.root}/config/cert/development/IgniteKeyDecrypted.key"))

      sig = private_key.sign(OpenSSL::Digest::SHA1.new, canon_string)
      Base64.encode64(sig).chomp
    end

    def signature_digest_value(xml)
      document = XMLSecurity::SignedDocument.new(xml)
      canoner = XML::Util::XmlCanonicalizer.new(false, true)
      canon_hashed_element = canoner.canonicalize(document)
      Base64.encode64(Digest::SHA1.digest(canon_hashed_element)).chomp
    end
  end
end