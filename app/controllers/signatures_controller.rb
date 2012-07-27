require 'sent_email_hasher'
require 'member_hasher'

class SignaturesController < ApplicationController
  def create
    petition = Petition.find(params[:petition_id])
    signature = Signature.new(params[:signature])
    signature.ip_address = connecting_ip
    signature.user_agent = request.env["HTTP_USER_AGENT"]
    signature.member = Member.find_or_initialize_by_email(email: signature.email, name: signature.name)
    signature.created_member = signature.member.new_record?
    member_hash = nil
    if signature.valid?
      begin
        petition.signatures.push signature
        Notifications.signed_petition signature
        petition.save!

        track_referals petition, signature, params
        signature.save!
        nps_win signature
        win! :signature
        member_hash = MemberHasher.generate(signature.member_id)
        cookies[:member_id] = {:value => member_hash, :expires => 100.years.from_now}
        flash[:signature_id] = signature.id
      rescue => ex
        Rails.logger.error "Error saving signature: #{ex} #{ex.backtrace.join}"
        flash.notice = ex.message
      end
    else
      flash[:invalid_signature] = signature
    end
    redirect_to petition_url(petition, l: member_hash)
  end

  private

  def track_referals petition, signature, params
    if h = SentEmailHasher.validate(params[:email_hash])
      sent_email = SentEmail.find_by_id(h)
      sent_email.signature ||= signature
      sent_email.save!
      signature.attributes = {referer: sent_email.member, reference_type: Signature::ReferenceType::EMAIL}
      petition.experiments.email(sent_email).win!(:signature)
    else
      referring_url = params[:referring_url]
      if h = MemberHasher.validate(params[:forwarded_notification_hash])
        referring_member = Member.find(h)
        signature.attributes = {referer: referring_member, reference_type: Signature::ReferenceType::FORWARDED_NOTIFICATION, referring_url: referring_url}
      elsif h = MemberHasher.validate(params[:fb_like_hash])
        referring_member = Member.find(h)
        signature.attributes = {referer: referring_member, reference_type: Signature::ReferenceType::FACEBOOK_LIKE, referring_url: referring_url}
        petition.experiments.facebook(referring_member).win!(:signature)
      elsif params[:fb_action_id].present?
        facebook_action = Share.find_by_action_id(params[:fb_action_id].to_s)
        referring_member = facebook_action.member
        signature.attributes = {referer: referring_member, reference_type: Signature::ReferenceType::FACEBOOK_SHARE, referring_url: referring_url}
        petition.experiments.facebook(referring_member).win!(:signature)
      elsif h = MemberHasher.validate(params[:fb_share_link_ref])
        referring_member = Member.find(h)
        signature.attributes = {referer: referring_member, reference_type: Signature::ReferenceType::FACEBOOK_POPUP, referring_url: referring_url}
        petition.experiments.facebook(referring_member).win!(:signature)
      elsif h = MemberHasher.validate(params[:twitter_hash])
        referring_member = Member.find(h)
        signature.attributes = {referer: referring_member, reference_type: Signature::ReferenceType::TWITTER, referring_url: referring_url}
      end
    end
  end

  def nps_win signature
    if signature.created_member
      win_on_option!("email_scheduler_nps", signature.petition.id.to_s)
      if (signature.reference_type == Signature::ReferenceType::FACEBOOK_LIKE || signature.reference_type == Signature::ReferenceType::FACEBOOK_SHARE || signature.reference_type == Signature::ReferenceType::FACEBOOK_POPUP) 
        win_on_option!("facebook sharing options", signature.reference_type)
      end
    end
  end
end
