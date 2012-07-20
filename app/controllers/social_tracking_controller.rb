class SocialTrackingController < ApplicationController
  def new
    win! :share
    facebook_action = params[:facebook_action]
    petition = Petition.find params[:petition_id]
    member = Signature.find(params[:signature_id]).member if params[:signature_id].present?
    action_id = params[:action_id]
    register_facebook_like petition, member if facebook_action == 'like'
    register_facebook_share petition, member, action_id if facebook_action == 'share'
    register_facebook_popup_opened petition, member if facebook_action == 'popup'
    render :text => ''
  end

  private

  def register_facebook_like petition, member
    like = Like.new
    like.petition = petition
    like.member = member if member.present?
    like.save!
  end

  def register_facebook_share petition, member, action_id
    share = Share.new
    share.petition = petition
    share.action_id = action_id if action_id.present?
    share.member = member if member.present?
    share.save!
  end

  def register_facebook_popup_opened petition, member
    share = Popup.new
    share.petition = petition
    share.member = member if member.present?
    share.save!
  end
end
