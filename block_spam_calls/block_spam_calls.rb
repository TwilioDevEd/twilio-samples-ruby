require 'sinatra'
require 'json'
require 'twilio-ruby'

post '/' do
    content_type 'text/xml'
    block_call = false

    if params.key? 'AddOns'
        add_ons = JSON.parse(params['AddOns'])
        if add_ons['status'] == 'successful'
            block_call = (
                marchex_blocked?(add_ons['results']['marchex_cleancall']) or
                nomorobo_blocked?(add_ons['results']['nomorobo_spamscore']) or
                whitepages_blocked?(add_ons['results']['whitepages_pro_phone_rep'])
            )
        end
    end

    response = Twilio::TwiML::Response.new do |r|
        if block_call
            r.Reject
        else
            r.Say 'Welcome to the jungle'
            r.Hangup
        end
    end

    response.to_xml
end


def marchex_blocked? marchex
    return false if marchex.nil? or marchex['status'] != 'successful'

    recommendation = marchex.dig('result', 'result', 'recommendation')
    return recommendation == 'BLOCK'
end


def nomorobo_blocked? nomorobo
    return false if nomorobo.nil? or nomorobo['status'] != 'successful'

    return nomorobo.dig('result', 'score') == 1
end


def whitepages_blocked? whitepages
    return false if whitepages.nil? or whitepages['status'] != 'successful'

    results = whitepages.dig('result', 'results')
    results.each do |result|
        return true if result.dig('reputation', 'level') == 4
    end unless results.nil?
    return false
end