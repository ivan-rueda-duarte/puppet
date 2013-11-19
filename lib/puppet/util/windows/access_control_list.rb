# Windows Access Control List
#
# Represents a list of access control entries (ACEs).
#
# @see http://msdn.microsoft.com/en-us/library/windows/desktop/aa374872(v=vs.85).aspx
# @api private
class Puppet::Util::Windows::AccessControlList
  include Enumerable

  ACCESS_ALLOWED_ACE_TYPE                 = 0x0
  ACCESS_DENIED_ACE_TYPE                  = 0x1

  # Construct an ACL.
  #
  # @param acl [Enumerable] A list of aces to copy from.
  def initialize(acl = nil)
    if acl
      @aces = acl.map(&:dup)
    else
      @aces = []
    end
  end

  # Enumerate each ACE in the list.
  #
  # @yieldparam ace [Hash] the ace
  def each
    @aces.each {|ace| yield ace}
  end

  # Allow the +sid+ to access a resource with the specified access +mask+.
  #
  # @param sid [String] The SID that the ACE is granting access to
  # @param mask [int] The access mask granted to the SID
  # @param flags [int] The flags assigned to the ACE, e.g. +INHERIT_ONLY_ACE+
  def allow(sid, mask, flags = 0)
    @aces << Puppet::Util::Windows::AccessControlEntry.new(sid, mask, flags, ACCESS_ALLOWED_ACE_TYPE)
  end

  # Deny the +sid+ access to a resource with the specified access +mask+.
  #
  # @param sid [String] The SID that the ACE is denying access to
  # @param mask [int] The access mask denied to the SID
  # @param flags [int] The flags assigned to the ACE, e.g. +INHERIT_ONLY_ACE+
  def deny(sid, mask, flags = 0)
    @aces << Puppet::Util::Windows::AccessControlEntry.new(sid, mask, flags, ACCESS_DENIED_ACE_TYPE)
  end

  # Reassign all ACEs currently assigned to +old_sid+ to +new_sid+ instead.
  # If an ACE is inherited or is not assigned to +old_sid+, then it will
  # be copied as-is to the new ACL, preserving its order within the ACL.
  #
  # @param old_sid [String] The old SID, e.g. 'S-1-5-18'
  # @param new_sid [String] The new SID
  # @return [AccessControlList] The copied ACL.
  def reassign!(old_sid, new_sid)
    new_aces = []
    prepend_needed = false

    @aces.each do |ace|
      new_ace = ace.dup

      if ace.sid == old_sid && ! ace.inherited?
        new_ace.sid = new_sid

        prepend_needed = old_sid == Win32::Security::SID::LocalSystem
      end

      new_aces << new_ace
    end

    if prepend_needed
      mask = Windows::Security::STANDARD_RIGHTS_ALL | Windows::Security::SPECIFIC_RIGHTS_ALL
      ace = Puppet::Util::Windows::AccessControlEntry.new(
              Win32::Security::SID::LocalSystem,
              mask)
      new_aces.unshift(ace)
    end

    @aces = new_aces
  end
end
