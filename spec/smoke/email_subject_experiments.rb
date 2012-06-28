require 'smoke_spec_helper'

describe "creating an email subject experiment" do

  it "awards a win against the email subject when email recipient signs" do
  	petition = create_a_featured_petition "Multiple email subjects!", "Yes indeed", ["Subject A", "Subject B"]
	  member = subscribe_member
	  send_petition_email petition.id, member.id
	  SentEmail.last.email.should == member.email
	  as_admin do
	    # visit /admin/experiments
	    go_to 'admin/experiments'
	    # make sure the number spins is 1 and wins is 0 for your subject
			email_experiments = element(xpath: "//table[@id = 'petition #{petition.id} email title']")
		  spins = email_experiments.find_element(xpath: "tbody/tr/td[@class='spins']").text.to_i
		  wins = email_experiments.find_element(xpath: "tbody/tr/td[@class='wins']").text.to_i
	    spins.should == 1
		  wins.should == 0
	  end
	  
	  # receive an email
	  # make sure its subject is your subject
	  # click on the link
	  # sign the petition
	  # visit /admin/experiments
	  # make sure the number spins is 1 and wins is 1 for your subject
	end
  
  #pending "editing subject should start a new test"
  # go back to editing your petition
  # change both of the subjects
  # save
  # send an email
  # visit /admin/experiments
  # make sure the number of spins is 1 and wins 1 for the old subject
  # make sure the number of spins is 1 for a new subject

end

def send_petition_email petition_id, member_id
	as_admin do
		on_demand_email_path = "admin/on_demand_email/new?petition_id=#{petition_id}&member_id=#{member_id}"
		go_to on_demand_email_path
	end
end

def subscribe_member name = 'A Member', email = 'amember@some.com'
	go_to 'subscribe'
	type(name).into(id: 'member_name')
	type(email).into(id: 'member_email')
	click id: 'sign-up-submit'
	Member.last
end