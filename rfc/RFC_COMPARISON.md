# RFC 1459 vs RFC 2812 Comparison

This document compares RFC 1459 (Internet Relay Chat Protocol, May 1993) with RFC 2812 (Internet Relay Chat: Client Protocol, April 2000).

RFC 2812 updates RFC 1459 with clarifications, new features, and protocol refinements.

---

## Section 2: The IRC Specification / Client Specification

### Summary
Section 2 underwent significant changes between RFC 1459 and RFC 2812. The most notable change is the scope narrowing: RFC 2812 focuses exclusively on client-to-server protocol, while RFC 1459 covered both client-to-server and server-to-server. The BNF notation was upgraded from "pseudo" BNF to formal Augmented BNF (ABNF) with precise hexadecimal notation. A new subsection on wildcard expressions (2.5) was added in RFC 2812.

### Key Differences

- **Title Change**: "The IRC Specification" (RFC 1459) → "The IRC Client Specification" (RFC 2812)
- **Scope**: RFC 1459 covered both client-server and server-server; RFC 2812 is client-only
- **BNF Format**: Upgraded from informal "pseudo" BNF to formal Augmented BNF with hexadecimal codes
- **NEW Section 2.5**: Wildcard expressions added in RFC 2812 (not in RFC 1459)
- **Character Set**: Expanded lowercase equivalents from {}| → []\\ to {}|^ → []\\~
- **Parameter Limits**: RFC 2812 explicitly specifies maximum 14 middle parameters in ABNF
- **Simplified Notes**: Reduced from 6 notes to 2 in the message format section
- **Enhanced Precision**: RFC 2812 uses MUST/SHALL keywords and removes ambiguities

### Details

#### 2.1 Overview

**RFC 1459:**
> The protocol as described herein is for use both with server to server and client to server connections. There are, however, more restrictions on client connections (which are considered to be untrustworthy) than on server connections.

**RFC 2812:**
> The protocol as described herein is for use only with client to server connections when the client registers as a user.

**Analysis:** RFC 2812 explicitly narrows the scope to client protocol only, reflecting the split of the specification into separate client (RFC 2812) and server (RFC 2813) documents.

#### 2.2 Character codes

**RFC 1459:**
- Mentions IRC's "scandanavian" origin (typo)
- States that {}| are lowercase equivalents of []\
- Applies to nickname equivalence only

**RFC 2812:**
- Corrects to "Scandinavian"
- Expands to {}|^ as lowercase of []\\~
- Explicitly applies to both nickname AND channel name equivalence

**Analysis:** RFC 2812 corrects the spelling error, adds the caret/tilde pair, and clarifies that case mapping applies to channel names as well as nicknames.

#### 2.3 Messages

**RFC 1459:**
- "send eachother" (spacing issue)
- Parameters: "up to 15"
- Separated by "one (or more) ASCII space character(s) (0x20)"

**RFC 2812:**
- "send each other" (corrected)
- Parameters: "maximum of fifteen (15)"
- Separated by "one ASCII space character (0x20) each"

**Analysis:** RFC 2812 clarifies that exactly one space separates components (not one or more), making parsing more deterministic.

#### 2.3.1 Message Format in BNF

**RFC 1459: "Message format in 'pseudo' BNF"**

Uses informal BNF notation:
```
<message>  ::= [':' <prefix> <SPACE> ] <command> <params> <crlf>
<prefix>   ::= <servername> | <nick> [ '!' <user> ] [ '@' <host> ]
<command>  ::= <letter> { <letter> } | <number> <number> <number>
<SPACE>    ::= ' ' { ' ' }
<params>   ::= <SPACE> [ ':' <trailing> | <middle> <params> ]
```

**RFC 2812: "Message format in Augmented BNF"**

Uses formal ABNF with hexadecimal codes:
```
message    =  [ ":" prefix SPACE ] command [ params ] crlf
prefix     =  servername / ( nickname [ [ "!" user ] "@" host ] )
command    =  1*letter / 3digit
params     =  *14( SPACE middle ) [ SPACE ":" trailing ]
           =/ 14( SPACE middle ) [ SPACE [ ":" ] trailing ]

nospcrlfcl =  %x01-09 / %x0B-0C / %x0E-1F / %x21-39 / %x3B-FF
                ; any octet except NUL, CR, LF, " " and ":"
middle     =  nospcrlfcl *( ":" / nospcrlfcl )
trailing   =  *( ":" / " " / nospcrlfcl )

SPACE      =  %x20        ; space character
crlf       =  %x0D %x0A   ; "carriage return" "linefeed"
```

**Key Changes:**
- Formal ABNF notation following RFC 2234
- Hexadecimal character codes (%x20, %x0D, %x0A, etc.)
- Explicit parameter limit: `*14( SPACE middle )` means 0-14 middle parameters
- More precise character set definitions using hex ranges
- Removes `<SPACE>` allowing multiple spaces; RFC 2812 requires exactly one

#### Notes Section Changes

**RFC 1459 had 6 notes:**
1. SPACE is only 0x20, not TAB or other whitespace
2. All extracted parameters are equal
3. CR/LF restriction is artifact, might change later
4. NUL character handling
5. Last parameter may be empty
6. Extended prefix usage restrictions

**RFC 2812 reduced to 2 notes:**
1. All extracted parameters are equal (same as RFC 1459 #2)
2. NUL character handling (simplified from RFC 1459 #4)

**Removed notes:**
- Note 3 about CR/LF being an artifact - no longer mentioned, indicating the framing is stable
- Note 5 about empty last parameter - presumably well-understood
- Note 6 about extended prefix - moved to other sections or considered obvious

#### Parameter Syntax Definitions

**RFC 1459:**
- Uses informal syntax with references like "see RFC 952 [DNS:4]"
- Basic definitions: `<nick>`, `<user>`, `<host>`, `<channel>`, `<mask>`
- Special characters: `-` `[` `]` `\` `` ` `` `^` `{` `}`

**RFC 2812:**
- Formal ABNF with hexadecimal ranges
- Much more detailed: adds `ip4addr`, `ip6addr`, `hostname`, `hostaddr`, `channelid`, `targetmask`, `chanstring`, `key`, `hexdigit`
- Special characters: `[` `]` `\` `` ` `` `_` `^` `{` `|` `}` (adds underscore and pipe)
- Includes detailed NOTES about hostname length limits (63 chars max due to 512-byte message limit)
- Specifies IPv6 address format
- Channel types expanded: `#`, `+`, `!` (with channelid), `&`

**Example of precision improvement:**

RFC 1459:
```
<host> ::= see RFC 952 [DNS:4] for details on allowed hostnames
```

RFC 2812:
```
host       =  hostname / hostaddr
hostname   =  shortname *( "." shortname )
shortname  =  ( letter / digit ) *( letter / digit / "-" )
              *( letter / digit )
                ; as specified in RFC 1123 [HNAME]
hostaddr   =  ip4addr / ip6addr
ip4addr    =  1*3digit "." 1*3digit "." 1*3digit "." 1*3digit
ip6addr    =  1*hexdigit 7( ":" 1*hexdigit )
ip6addr    =/ "0:0:0:0:0:" ( "0" / "FFFF" ) ":" ip4addr
```

#### 2.4 Numeric replies

**RFC 1459:**
- Uses lowercase "must"
- Mentions "silently dropped" for client-originated numeric replies
- References "section 6" for reply list

**RFC 2812:**
- Uses uppercase "MUST" (RFC 2119 keywords)
- Removes "silently" - just says not allowed from client
- References "section 5 (Replies)"

**Analysis:** RFC 2812 adopts RFC 2119 requirement level keywords and updates section references.

#### 2.5 Wildcard expressions (NEW in RFC 2812)

This entire subsection is new in RFC 2812 and did not exist in RFC 1459.

**Content:**
- Defines "mask" as a string with wildcards
- `?` (%x3F) matches exactly one character
- `*` (%x2A) matches any number of any characters
- `\` (%x5C) escapes wildcards
- Formal ABNF syntax provided
- Examples given:
  - `a?c` - matches 3-character strings starting with "a" and ending with "c"
  - `a*c` - matches strings of at least 2 characters starting with "a" and ending with "c"

**Significance:** This formalization of wildcard matching ensures consistent implementation across IRC servers and clients. RFC 1459 used wildcards but never formally defined their behavior.

---

## Section 3: IRC Concepts (RFC 1459 only)

### Summary
Section 3 "IRC Concepts" exists in RFC 1459 (pages 10-12) but was completely removed from RFC 2812. This section provided foundational explanations of IRC's communication patterns and message routing concepts. The architectural discussion was likely moved to RFC 2810 (Internet Relay Chat: Architecture), which RFC 2812 explicitly references in its abstract.

### Content from RFC 1459
RFC 1459 Section 3 "IRC Concepts" covered three main communication patterns with detailed examples using a sample network topology (servers A, B, C, D, E and clients 1, 2, 3, 4):

**3.1 One-to-one communication**
- Described private messaging between individual clients
- Explained how messages travel along the shortest path on the spanning tree
- Provided examples showing message routing between different client pairs (e.g., clients 1-2, 1-3, 2-4)

**3.2 One-to-many**
- Explained IRC's conferencing capabilities with three mechanisms:
  - **3.2.1 To a list**: Sending to multiple destinations via a comma-separated list (noted as inefficient due to duplicate message dispatch)
  - **3.2.2 To a group (channel)**: The primary IRC communication method, where channels act like multicast groups and messages are efficiently sent only to servers with users in that channel
  - **3.2.3 To a host/server mask**: Allowing IRC operators to send messages to users matching specific host/server patterns

**3.3 One-to-all**
- Discussed broadcast messages sent to all clients and/or servers:
  - **3.3.1 Client-to-Client**: Noted that no message class allows broadcasting from one client to all others
  - **3.3.2 Client-to-Server**: State changes (channel membership, modes, user status) must be sent to all servers by default
  - **3.3.3 Server-to-Server**: Messages affecting users, channels, or servers are broadcast to all connected servers

### Status in RFC 2812
**Removed entirely from the Client Protocol specification.**

RFC 2812 takes a different structural approach:
- **Section 1 (Labels)**: Defines basic identifiers (servers, clients, channels) without conceptual explanation
- **Section 2 (The IRC Client Specification)**: Covers message format and syntax
- **Section 3 (Message Details)**: Jumps directly into specific command documentation

The abstract of RFC 2812 explicitly states: "This document defines the Client Protocol, and assumes that the reader is familiar with the IRC Architecture [IRC-ARCH]." This reference is to **RFC 2810** ("Internet Relay Chat: Architecture", April 2000), which likely contains the architectural and conceptual material that was previously in RFC 1459 Section 3.

**Key differences:**
1. RFC 1459 was a monolithic specification containing architecture, concepts, and protocol details
2. RFC 2812 is part of a split specification focusing only on client protocol commands and responses
3. The conceptual foundation (spanning trees, message routing patterns, broadcast semantics) was extracted to the separate Architecture document (RFC 2810)
4. RFC 2812 only briefly mentions "broadcast" once (in the context of wildcard message targets) and "conferencing" once (in the abstract), without the detailed explanations found in RFC 1459

**Implicit coverage:**
While the formal conceptual discussion is gone, the underlying concepts are implicitly reflected in:
- Section 3.3 "Sending messages" describes PRIVMSG and NOTICE but doesn't explain the routing theory
- Section 3.2 "Channel operations" documents channel commands without explaining the multicast-like efficiency
- The behavior is embedded in command specifications rather than explained as architectural concepts

---

## Sections 4.4-4.5/3.3,3.5,3.6: Sending Messages & User Queries

### Summary

RFC 2812 refines the messaging and user query commands with more precise terminology, RFC 2119 compliance (MUST/MUST NOT keywords), and ABNF syntax notation. The most significant addition is Section 3.5 introducing service-oriented commands (SERVLIST and SQUERY) that were not present in RFC 1459. Parameter names are standardized (e.g., "msgtarget" instead of "receiver", "mask" instead of "name", "target" instead of "server"), and several commands gain enhanced functionality through multiple parameter support and wildcard capabilities.

### Key Differences

- **Terminology Standardization**: RFC 2812 uses consistent parameter names across commands ("msgtarget", "mask", "target" vs RFC 1459's varied terminology)
- **RFC 2119 Keywords**: RFC 2812 uses formal "MUST" and "MUST NOT" keywords for requirements (previously "must" in RFC 1459)
- **ABNF Notation**: RFC 2812 uses proper ABNF syntax for parameter definitions (e.g., `*( "," <nickname> )`)
- **NEW Service Commands**: Section 3.5 introduces SERVLIST and SQUERY for service interaction (completely new in RFC 2812)
- **Enhanced Functionality**: WHOWAS supports multiple comma-separated nicknames; wildcard support added to WHOIS and WHOWAS target parameters
- **Clearer Documentation**: RFC 2812 provides more detailed examples and explicit feature descriptions

### Details

#### 3.3.1/4.4.1 PRIVMSG (Private Messages)

**Parameter Changes:**
- RFC 1459: `<receiver>{,<receiver>} <text to be sent>`
- RFC 2812: `<msgtarget> <text to be sent>`

**Description Improvements:**
- RFC 1459 describes PRIVMSG as used "to send private messages between users" with receiver being "the nickname of the receiver" that "can also be a list of names or channels separated with commas"
- RFC 2812 explicitly states it's used "to send private messages between users, as well as to send messages to channels" and that msgtarget is "usually the nickname of the recipient of the message, or a channel name"
- Both support host mask (#<mask>) and server mask ($<mask>) with identical wildcard restrictions

**Additional Examples in RFC 2812:**
- Adds user@host%relay format examples:
  - `PRIVMSG kalt%millennium.stealth.net@irc.stealth.net :Are you a frog?` (user on remote server via relay)
  - `PRIVMSG kalt%millennium.stealth.net :Do you like cheese?` (user on local server)
  - `PRIVMSG Wiz!jto@tolsun.oulu.fi :Hello !` (user with full identity)

**Section Introduction:**
- RFC 1459: States "PRIVMSG and NOTICE are the only messages available which actually perform delivery of a text message"
- RFC 2812: Updates to "PRIVMSG, NOTICE and SQUERY (described in Section 3.5 on Service Query and Commands) are the only messages available which actually perform delivery of a text message" - acknowledging the new service query functionality

#### 3.3.2/4.4.2 NOTICE

**Parameter Changes:**
- RFC 1459: `<nickname> <text>`
- RFC 2812: `<msgtarget> <text>`
- The change from "nickname" to "msgtarget" allows NOTICE to be sent to channels and other targets, not just users

**RFC 2119 Compliance:**
- RFC 1459: "automatic replies must never be sent" and "they must not send any error reply"
- RFC 2812: "automatic replies MUST NEVER be sent" and "they MUST NOT send any error reply" (formal RFC 2119 keywords)

**Content Otherwise Identical:**
- Both describe the same loop-prevention purpose
- Both mention automatons (clients with AI or interactive programs)
- Both reference PRIVMSG for more details on replies and examples

#### 3.5 Service Query and Commands (NEW in RFC 2812)

This entire section is **completely new** in RFC 2812 and has no equivalent in RFC 1459.

**3.5.1 SERVLIST Message:**
- Command: SERVLIST
- Parameters: `[ <mask> [ <type> ] ]`
- Purpose: Lists services currently connected to the network and visible to the user
- Optional parameters restrict results to matching service names and types
- Numeric Replies: RPL_SERVLIST, RPL_SERVLISTEND

**3.5.2 SQUERY:**
- Command: SQUERY
- Parameters: `<servicename> <text>`
- Purpose: Similar to PRIVMSG but recipient MUST be a service
- Only way for a text message to be delivered to a service
- Examples:
  - `SQUERY irchelp :HELP privmsg` (message to service with nickname)
  - `SQUERY dict@irc.fr :fr2en blaireau` (message to service with name)

#### 3.6.1/4.5.1 WHO Query

**Parameter Changes:**
- RFC 1459: `[<name> [<o>]]`
- RFC 2812: `[ <mask> [ "o" ] ]`
- RFC 2812 uses "mask" terminology and quotes the "o" parameter

**Description Refinements:**
- RFC 1459: "returns a list of information which 'matches' the <name> parameter"
- RFC 2812: "returns a list of information which 'matches' the <mask> parameter"
- RFC 2812 adds explicit phrase: "will end up matching every **visible user**" (emphasis on visibility)

**Visibility Rules (Identical):**
- Both define visible users as those who aren't invisible (user mode +i) and who don't have a common channel with requesting client
- Both support "0" or wildcards to match all visible users
- Both match against users' host, server, real name and nickname if channel cannot be found

**Operator Filter:**
- Both support "o" parameter to return only operators according to the mask
- Numeric replies identical: ERR_NOSUCHSERVER, RPL_WHOREPLY, RPL_ENDOFWHO

#### 3.6.2/4.5.2 WHOIS Query

**Parameter Changes:**
- RFC 1459: `[<server>] <nickmask>[,<nickmask>[,...]]`
- RFC 2812: `[ <target> ] <mask> *( "," <mask> )`
- RFC 2812 uses "target" instead of "server" and ABNF notation for comma-separated list

**New Feature in RFC 2812:**
- Adds: "Wildcards are allowed in the <target> parameter" (not mentioned in RFC 1459)

**Server Parameter Description:**
- RFC 1459: Describes it as "the latter version sends the query to a specific server"
- RFC 2812: More precise: "If the <target> parameter is specified, it sends the query to a specific server"

**Idle Time Explanation (Identical):**
- Both explain that only the local server (server user is directly connected to) knows idle information
- Both note that everything else is globally known

**Numeric Replies (Identical):**
- ERR_NOSUCHSERVER, ERR_NONICKNAMEGIVEN, RPL_WHOISUSER, RPL_WHOISCHANNELS (listed twice in both), RPL_WHOISSERVER, RPL_AWAY, RPL_WHOISOPERATOR, RPL_WHOISIDLE, ERR_NOSUCHNICK, RPL_ENDOFWHOIS

**Examples (Identical):**
- Both use same examples: `WHOIS wiz` and `WHOIS eff.org trillian`

#### 3.6.3/4.5.3 WHOWAS

**Parameter Changes:**
- RFC 1459: `<nickname> [<count> [<server>]]`
- RFC 2812: `<nickname> *( "," <nickname> ) [ <count> [ <target> ] ]`
- **Major enhancement**: RFC 2812 supports multiple comma-separated nicknames in a single query
- Uses "target" instead of "server" (consistent with other commands)

**New Feature in RFC 2812:**
- Adds: "Wildcards are allowed in the <target> parameter" (not in RFC 1459)

**Core Functionality (Identical):**
- Both query information about nicknames that no longer exist
- Both search nickname history backward (most recent first)
- Both support <count> parameter to limit results (all if not specified)
- Both interpret non-positive count as full search
- Both explicitly state "no wild card matching" for nicknames

**Numeric Replies (Identical):**
- ERR_NONICKNAMEGIVEN, ERR_WASNOSUCHNICK, RPL_WHOWASUSER, RPL_WHOISSERVER, RPL_ENDOFWHOWAS

**Examples (Identical):**
- `WHOWAS Wiz` - return all information
- `WHOWAS Mermaid 9` - return at most 9 most recent entries
- `WHOWAS Trillian 1 *.edu` - most recent history from first server matching *.edu

#### User Queries Section Introduction

**RFC 1459 (Section 4.5):**
- Basic description of user queries as commands for finding user details
- Describes visibility based on user mode and common channels

**RFC 2812 (Section 3.6):**
- Same core description but adds: "Although services SHOULD NOT be using this class of message, they are allowed to."
- This acknowledges the service infrastructure introduced in Section 3.5

---


## Section 4.1/3.1: Connection Registration

### Summary

RFC 2812 significantly refactored the connection registration process compared to RFC 1459. While both RFCs cover similar core messages (PASS, NICK, USER, OPER, QUIT, SQUIT), RFC 2812 introduced two new messages (User MODE and SERVICE), removed server-specific functionality from the client protocol, simplified several message formats, and provided more precise specifications for registration order and parameters.

### Key Differences

- **NICK message simplified**: RFC 2812 removed the `<hopcount>` parameter that was used in RFC 1459 for server-to-server communication
- **USER message redesigned**: RFC 2812 replaced `<hostname>` and `<servername>` parameters with `<mode>` (bitmask) and `<unused>` parameters, allowing automatic user mode setting during registration
- **PASS message clarified**: RFC 2812 explicitly states PASS is optional and must precede NICK/USER or SERVICE, while RFC 1459 stated it "can and must be set"
- **SERVER message removed**: RFC 1459's SERVER message (4.1.4) is not in RFC 2812's connection registration section, as RFC 2812 focuses on client protocol
- **SERVICE message added**: RFC 2812 introduced the SERVICE message (3.1.6) for registering services with distribution and type parameters
- **User MODE message added**: RFC 2812 added dedicated User mode message (3.1.5) to the connection registration section with detailed mode flags (a, i, w, r, o, O, s)
- **QUIT message simplified**: RFC 2812 simplified QUIT description, removing detailed netsplit handling from this section
- **SQUIT restrictions**: RFC 2812 explicitly states SQUIT is "available only to operators" and added ERR_NEEDMOREPARAMS error
- **Error codes expanded**: RFC 2812 added new error codes like ERR_UNAVAILRESOURCE and ERR_RESTRICTED for NICK
- **Registration order specified**: RFC 2812 provides explicit RECOMMENDED order: PASS → NICK/SERVICE → USER

### Details

#### 4.1.1/3.1.1: Password Message (PASS)

**RFC 1459:**
- Command: `PASS <password>`
- States password "can and must be set" before registration
- Must precede NICK/USER for clients
- Must precede SERVER command for servers
- Multiple PASS commands allowed, only last one used

**RFC 2812:**
- Command: `PASS <password>`
- Explicitly states password is "optional"
- MUST precede NICK/USER combination or SERVICE command
- No mention of server-specific usage (client protocol focus)
- Clearer specification: "MUST be set before any attempt to register"

**Changes:**
- Clarified that PASS is optional
- Removed server-specific SERVER command reference
- More precise language about when PASS must be sent

#### 4.1.2/3.1.2: Nick/Nickname Message

**RFC 1459:**
- Command: `NICK <nickname> [ <hopcount> ]`
- Includes optional `<hopcount>` parameter for servers (indicates distance from home server)
- Local connection has hopcount of 0
- Client-supplied hopcount must be ignored
- Detailed nickname collision handling: all instances removed, KILL command issued to all servers
- May issue ERR_NICKCOLLISION for direct connections
- Error codes: ERR_NONICKNAMEGIVEN, ERR_ERRONEUSNICKNAME, ERR_NICKNAMEINUSE, ERR_NICKCOLLISION

**RFC 2812:**
- Command: `NICK <nickname>`
- No `<hopcount>` parameter (removed)
- Simplified to just nickname parameter
- No detailed collision handling in message description
- Error codes: ERR_NONICKNAMEGIVEN, ERR_ERRONEUSNICKNAME, ERR_NICKNAMEINUSE, ERR_NICKCOLLISION, ERR_UNAVAILRESOURCE, ERR_RESTRICTED (added)

**Changes:**
- Removed `<hopcount>` parameter entirely
- Added ERR_UNAVAILRESOURCE and ERR_RESTRICTED error codes
- Removed detailed collision handling description (likely moved to server protocol document)
- Simplified message format

#### 4.1.3/3.1.3: User Message

**RFC 1459:**
- Command: `USER <username> <hostname> <servername> <realname>`
- Four distinct parameters
- Used for both client registration and server-to-server communication
- `<hostname>` and `<servername>` ignored from direct clients for security
- Must be prefixed with NICK when sent between servers
- Mentions Identity Server for username verification
- `<realname>` must be last parameter, prefixed with `:`, may contain spaces

**RFC 2812:**
- Command: `USER <user> <mode> <unused> <realname>`
- Four parameters but completely different middle parameters
- `<mode>` is numeric bitmask for automatic user mode setting:
  - Bit 2 set → user mode 'w' (wallops)
  - Bit 3 set → user mode 'i' (invisible)
- `<unused>` parameter (typically `*`)
- `<realname>` may contain spaces (no explicit `:` prefix requirement mentioned)
- No mention of server-to-server usage or Identity Server

**Changes:**
- Replaced `<hostname>` and `<servername>` with `<mode>` and `<unused>`
- Added automatic user mode setting capability via bitmask
- Removed server-to-server communication details (client protocol focus)
- Removed Identity Server mention
- Example changed from `USER guest tolmoon tolsun :Ronnie Reagan` to `USER guest 0 * :Ronnie Reagan`

#### 4.1.4: Server Message (RFC 1459 only)

**RFC 1459:**
- Command: `SERVER <servername> <hopcount> <info>`
- Used to register server connections
- Broadcasts server information across network
- Only accepted from unregistered connections or existing server connections
- Errors typically result in connection termination via ERROR command
- Duplicate servers cause connection closure

**RFC 2812:**
- Not present in Section 3.1 (Connection Registration)
- CLIENT protocol document focuses on user/service registration
- Server protocol likely covered in separate RFC 2813

#### 3.1.6: Service Message (RFC 2812 only - NEW)

**RFC 2812:**
- Command: `SERVICE <nickname> <reserved> <distribution> <type> <reserved> <info>`
- NEW message not in RFC 1459
- Registers a new service on the network
- `<distribution>` specifies service visibility (mask matching)
- `<type>` reserved for future usage
- Two reserved parameters
- Error codes: ERR_ALREADYREGISTRED, ERR_NEEDMOREPARAMS, ERR_ERRONEUSNICKNAME
- Success codes: RPL_YOURESERVICE, RPL_YOURHOST, RPL_MYINFO
- Example: `SERVICE dict * *.fr 0 0 :French Dictionary`

#### 4.1.5/3.1.4: Oper/Operator Message

**RFC 1459:**
- Command: `OPER <user> <password>`
- Used by normal user to obtain operator privileges
- Server informs network via "MODE +o" for client's nickname
- Client-server only message
- Error codes: ERR_NEEDMOREPARAMS, RPL_YOUREOPER, ERR_NOOPERHOST, ERR_PASSWDMISMATCH

**RFC 2812:**
- Command: `OPER <name> <password>`
- "A normal user uses the OPER command to obtain operator privileges"
- User receives MODE message upon success (see section 3.1.5)
- Parameter name changed from `<user>` to `<name>`
- Same error codes: ERR_NEEDMOREPARAMS, RPL_YOUREOPER, ERR_NOOPERHOST, ERR_PASSWDMISMATCH

**Changes:**
- Parameter renamed: `<user>` → `<name>`
- Added reference to MODE message (section 3.1.5) for success notification
- Slightly different wording but same functionality

#### 3.1.5: User Mode Message (RFC 2812 only - NEW)

**RFC 2812:**
- Command: `MODE <nickname> *( ( "+" / "-" ) *( "i" / "w" / "o" / "O" / "r" ) )`
- NEW section added to connection registration
- User MODE command must only be accepted if sender and nickname parameter match
- Available modes:
  - `a` - user flagged as away
  - `i` - marks user as invisible
  - `w` - user receives wallops
  - `r` - restricted user connection
  - `o` - operator flag
  - `O` - local operator flag
  - `s` - marks user for server notices (obsolete)
- Flag `a` SHALL NOT be toggled via MODE (use AWAY command)
- Users cannot set +o/+O (must use OPER command)
- Users cannot unset -r restriction
- Error codes: ERR_NEEDMOREPARAMS, ERR_USERSDONTMATCH, ERR_UMODEUNKNOWNFLAG, RPL_UMODEIS

**RFC 1459:**
- User modes existed but were not part of connection registration section
- No dedicated section in 4.1

#### 4.1.6/3.1.7: Quit Message

**RFC 1459:**
- Command: `QUIT [<Quit message>]`
- Server must close connection when QUIT received
- Quit message sent instead of default (nickname)
- Detailed netsplit handling: quit message composed of two server names
- First name: still connected server
- Second name: disconnected server
- If client dies without QUIT, server fills in appropriate message
- No numeric replies

**RFC 2812:**
- Command: `QUIT [ <Quit Message> ]`
- "A client session is terminated with a quit message"
- Server acknowledges by sending ERROR message to client
- No detailed netsplit handling in this section
- No numeric replies
- Example shows both client and server format

**Changes:**
- Added explicit mention of server sending ERROR message
- Removed detailed netsplit handling (moved elsewhere or to server protocol)
- Removed details about client dying without QUIT

#### 4.1.7/3.1.8: Server Quit Message (SQUIT)

**RFC 1459:**
- Command: `SQUIT <server> <comment>`
- Used to disconnect server links
- Also available to operators for network management
- Operators may issue for remote servers
- `<comment>` should be supplied by operators
- Both sides of closed connection send SQUIT for all servers behind link
- QUIT messages sent for all clients behind link
- Channel members notified of splits
- If premature termination, server informs network and fills in comment
- Error codes: ERR_NOPRIVILEGES, ERR_NOSUCHSERVER

**RFC 2812:**
- Command: `SQUIT <server> <comment>`
- "Available only to operators" (explicitly stated)
- Used to disconnect server links
- Servers can generate SQUIT on error conditions
- May target remote server connection (forwarded without affecting intermediate servers)
- `<comment>` SHOULD be supplied by operators
- Server generates WALLOPS message with comment
- Error codes: ERR_NOPRIVILEGES, ERR_NOSUCHSERVER, ERR_NEEDMOREPARAMS (added)

**Changes:**
- Explicitly restricted to operators only
- Added ERR_NEEDMOREPARAMS error code
- Simplified description, removed detailed propagation details
- Added WALLOPS notification for operators
- Removed detailed client QUIT and channel notification handling

---

## Section 5/4: Optional Messages / Features

### Summary

RFC 1459 Section 5 "OPTIONALS" and RFC 2812 Section 4 "Optional features" cover messages that are not required for a working IRC server implementation. RFC 2812 introduces one new command (DIE), adds security guidance, formalizes language using RFC 2119 keywords (MUST, SHOULD, MAY), and clarifies server-to-server behavior. The WALLOPS command also underwent a significant change in its target audience.

### Key Differences

- **New Command**: DIE command introduced in RFC 2812 for server shutdown
- **Security Enhancements**: RFC 2812 adds strong security warnings for USERS command (should be disabled by default, require recompilation to enable)
- **Language Formalization**: RFC 2812 uses RFC 2119 keywords (MUST, SHOULD, MAY) throughout instead of informal language
- **WALLOPS Target Change**: RFC 1459 sends to "all operators currently online" vs RFC 2812 sends to "all currently connected users who have set the 'w' user mode"
- **AWAY Optimization**: RFC 2812 adds guidance about bandwidth/memory costs and recommends using user mode 'a' for server-to-server updates
- **Parameter Syntax**: RFC 2812 uses formal ABNF notation for parameters (e.g., `*( SPACE <nickname> )` instead of `{<space><nickname>}`)
- **SUMMON Enhancement**: RFC 2812 adds optional `<channel>` parameter

### Details

#### 4.1 AWAY Message

**RFC 1459 (5.1)**:
- Parameters: `[message]`
- Basic description: Sets automatic reply for PRIVMSG commands
- No guidance on server-to-server usage

**RFC 2812 (4.1)**:
- Parameters: `[ <text> ]`
- Same basic functionality
- **NEW**: Adds important optimization guidance: "Because of its high cost (memory and bandwidth wise), the AWAY message SHOULD only be used for client-server communication"
- **NEW**: "A server MAY choose to silently ignore AWAY messages received from other servers"
- **NEW**: Recommends using user mode 'a' to update away status across servers instead

**Analysis**: RFC 2812 recognizes AWAY as a resource-intensive command and provides guidance to minimize its impact on server-to-server communication.

---

#### 4.2 REHASH Message

**RFC 1459 (5.2)**:
- "The rehash message can be used by the operator to force the server to re-read and process its configuration file"

**RFC 2812 (4.2)**:
- "The rehash command is an administrative command which can be used by an operator to force the server to re-read and process its configuration file"
- Changes "message" to "command" and adds "administrative" qualifier

**Analysis**: Minimal changes, primarily terminology refinement to emphasize administrative nature.

---

#### 4.3 DIE Message

**RFC 1459**: Not present

**RFC 2812 (4.3)**: **NEW COMMAND**
- Command: DIE
- Parameters: None
- "An operator can use the DIE command to shutdown the server"
- Similar structure to RESTART command
- "This message is optional since it may be viewed as a risk"
- "The DIE command MUST always be fully processed by the server to which the sending client is connected and MUST NOT be passed onto other connected servers"
- Numeric Replies: ERR_NOPRIVILEGES

**Analysis**: New administrative command for graceful server shutdown, parallel to RESTART command.

---

#### 4.4 RESTART Message

**RFC 1459 (5.3)**:
- "The restart message can only be used by an operator"
- "must always be fully processed by the server to which the sending client is connected and not be passed onto other connected servers" (lowercase)

**RFC 2812 (4.4)**:
- "An operator can use the restart command" (slightly different phrasing)
- "The RESTART command MUST always be fully processed by the server to which the sending client is connected and MUST NOT be passed onto other connected servers" (uppercase MUST/MUST NOT)

**Analysis**: Language formalized using RFC 2119 keywords for clarity and interoperability.

---

#### 4.5 SUMMON Message

**RFC 1459 (5.4)**:
- Parameters: `<user> [<server>]`
- "If summon is not enabled in a server, it must return the ERR_SUMMONDISABLED numeric and pass the summon message onwards"

**RFC 2812 (4.5)**:
- Parameters: `<user> [ <target> [ <channel> ] ]` - **NEW optional channel parameter**
- "If summon is not enabled in a server, it MUST return the ERR_SUMMONDISABLED numeric"
- **REMOVED**: No longer mentions "pass the summon message onwards"

**Analysis**: RFC 2812 adds channel parameter for more specific summoning and removes the requirement to forward SUMMON messages when disabled.

---

#### 4.6 USERS Message

**RFC 1459 (5.5)**:
- Parameters: `[<server>]`
- "Some people may disable this command on their server for security related reasons"
- "If disabled, the correct numeric must be returned to indicate this"

**RFC 2812 (4.6)**:
- Parameters: `[ <target> ]`
- **NEW**: "Because of the security implications of such a command, it SHOULD be disabled by default in server implementations"
- **NEW**: "Enabling it SHOULD require recompiling the server or some equivalent change rather than simply toggling an option and restarting the server"
- **NEW**: "The procedure to enable this command SHOULD also include suitable large comments"
- "If disabled, the correct numeric MUST be returned to indicate this" (uses MUST)

**Analysis**: RFC 2812 significantly strengthens security guidance, recognizing USERS as a privacy/security risk and recommending it be disabled by default with high barriers to enabling.

---

#### 4.7 OPERWALL (WALLOPS) Message

**RFC 1459 (5.6)**:
- Parameters: `Text to be sent to all operators currently online`
- "Sends a message to all operators currently online"
- "it is recommended that the current implementation of WALLOPS be used as an example by allowing and recognising only servers as the senders of WALLOPS"

**RFC 2812 (4.7)**:
- Parameters: `<Text to be sent>`
- **CHANGED**: "The WALLOPS command is used to send a message to all currently connected users who have set the 'w' user mode for themselves"
- "it is RECOMMENDED that the implementation of WALLOPS allows and recognizes only servers as the originators of WALLOPS" (uses formal RECOMMENDED)

**Analysis**: Significant change - RFC 2812 changes WALLOPS from operator-only to any user with 'w' mode, giving users more control. Language formalized with RFC 2119 RECOMMENDED.

---

#### 4.8 USERHOST Message

**RFC 1459 (5.7)**:
- Parameters: `<nickname>{<space><nickname>}`
- "The USERHOST command takes a list of up to 5 nicknames, each separated by a space character"
- No example of reply format

**RFC 2812 (4.8)**:
- Parameters: `<nickname> *( SPACE <nickname> )` (formal ABNF notation)
- Same functionality (up to 5 nicknames)
- **NEW**: Includes example reply: `:ircd.stealth.net 302 yournick :syrk=+syrk@millennium.stealth.net`

**Analysis**: Minor - mainly formatting improvements and added example for clarity.

---

#### 4.9 ISON Message

**RFC 1459 (5.8)**:
- Parameters: `<nickname>{<space><nickname>}`
- "ISON only takes one (1) parameter: a space-separated list of nicks"
- "as to cause the server to chop it off so it fits in 512 characters"
- "ISON is only be processed by the server local" (grammatical error)

**RFC 2812 (4.9)**:
- Parameters: `<nickname> *( SPACE <nickname> )` (formal ABNF notation)
- "ISON only takes one (1) type of parameter: a space-separated list of nicks" (clarifies "type of")
- "the combined length MUST NOT be too large as to cause the server to chop it off so it fits in 512 characters" (uses MUST NOT)
- "ISON is only processed by the server local" (grammar corrected)

**Analysis**: Language refinement with RFC 2119 keywords and grammatical corrections. Clarifies the parameter is one "type" (list) rather than one discrete value.

---

### Section Introduction Differences

**RFC 1459 Section 5 Header**:
- Title: "OPTIONALS"
- "In the absence of the option, an error reply message must be generated or an unknown command error"
- "it must be passed on (elementary parsing required)"

**RFC 2812 Section 4 Header**:
- Title: "Optional features"
- "In the absence of the feature, an error reply message MUST be generated or an unknown command error"
- "it MUST be passed on (elementary parsing REQUIRED)" (formalized with uppercase)
- **NEW**: "From this section, only the USERHOST and ISON messages are available to services"

**Analysis**: RFC 2812 clarifies that services (a special type of IRC entity) can only use USERHOST and ISON from the optional commands.

---
## Section 4.3/3.4: Server Queries and Commands

### Summary

RFC 2812's Section 3.4 significantly enhances and clarifies the server query commands from RFC 1459's Section 4.3. The major changes include: addition of two new commands (MOTD and LUSERS), standardization of parameter naming from `<server>` to `<target>`, explicit wildcard support for all commands, more formal specification language (using MUST, SHOULD, REQUIRED), and refinements to command semantics and return values.

### Key Differences

- **New Commands**: RFC 2812 adds MOTD (Message Of The Day) and LUSERS (network statistics) commands
- **Parameter Naming**: Consistent use of `<target>` instead of `<server>` across all commands
- **Wildcard Support**: RFC 2812 explicitly documents wildcard support in `<target>` parameter for all commands
- **Specification Language**: RFC 2812 uses RFC 2119 keywords (MUST, SHOULD, REQUIRED, RECOMMENDED) for clearer requirements
- **CONNECT Command**: Port parameter changed from optional to required in RFC 2812
- **STATS Command**: Reduced from 8 standard queries to 4, with measurement units changed from bytes to Kbytes
- **TRACE Command**: Enhanced with service support and additional numeric replies (RPL_TRACELOG, RPL_TRACEEND)
- **General Improvements**: More detailed operational specifications and clearer forwarding/routing semantics

### Details

#### 3.4.1 MOTD Message (NEW in RFC 2812)

**RFC 1459**: Not present

**RFC 2812**:
- **Command**: MOTD
- **Parameters**: [ <target> ]
- **Purpose**: Get the "Message Of The Day" of the given server
- **Wildcards**: Allowed in `<target>` parameter
- **Numeric Replies**: RPL_MOTDSTART, RPL_MOTD, RPL_ENDOFMOTD, ERR_NOMOTD

This is a completely new command introduced in RFC 2812 to standardize how clients retrieve server MOTD messages.

---

#### 3.4.2 LUSERS Message (NEW in RFC 2812)

**RFC 1459**: Not present

**RFC 2812**:
- **Command**: LUSERS
- **Parameters**: [ <mask> [ <target> ] ]
- **Purpose**: Get statistics about the size of the IRC network
- **Behavior**:
  - No parameters: Reply about whole network
  - With `<mask>`: Reply only about servers matching the mask
  - With `<target>`: Request forwarded to that server for reply generation
- **Wildcards**: Allowed in `<target>` parameter
- **Numeric Replies**: RPL_LUSERCLIENT, RPL_LUSEROP, RPL_LUSERUNKNOWN, RPL_LUSERCHANNELS, RPL_LUSERME, ERR_NOSUCHSERVER

This is a new command for network size statistics, providing structured information about users, operators, channels, etc.

---

#### 3.4.3/4.3.1 VERSION Message

**RFC 1459**:
- **Parameters**: [<server>]
- **Description**: "used to query the version of the server program"
- **Parameter behavior**: Optional `<server>` for querying non-directly-connected servers
- **Numeric Replies**: ERR_NOSUCHSERVER, RPL_VERSION

**RFC 2812**:
- **Parameters**: [ <target> ]
- **Description**: "used to query the version of the server program"
- **Parameter behavior**: Optional `<target>` for querying non-directly-connected servers
- **Wildcards**: Explicitly documented as allowed in `<target>` parameter
- **Numeric Replies**: ERR_NOSUCHSERVER, RPL_VERSION
- **Examples**: Simplified (only one example vs two in RFC 1459)

**Changes**:
- Parameter renamed from `<server>` to `<target>` for consistency
- Wildcard support explicitly documented
- One example removed (the :Wiz VERSION *.se example)

---

#### 3.4.4/4.3.2 STATS Message

**RFC 1459**:
- **Parameters**: [<query> [<server>]]
- **Query types documented**: c, h, i, k, l, m, o, y, u (9 types)
- **Measurement units**: bytes and messages
- **Specification**: "the server must be able to supply information as described by the queries below (or similar)"
- **Numeric Replies**: ERR_NOSUCHSERVER, RPL_STATSCLINE, RPL_STATSNLINE, RPL_STATSILINE, RPL_STATSKLINE, RPL_STATSQLINE, RPL_STATSLLINE, RPL_STATSLINKINFO, RPL_STATSUPTIME, RPL_STATSCOMMANDS, RPL_STATSOLINE, RPL_STATSHLINE, RPL_ENDOFSTATS

**RFC 2812**:
- **Parameters**: [ <query> [ <target> ] ]
- **Query types**: Standard queries SHOULD be supported (l, m, o, u - only 4 types)
- **Measurement units**: Kbytes and messages
- **Wildcards**: Allowed in `<target>` parameter
- **Specification**: "list of valid queries is implementation dependent" with recommendations
- **Additional recommendation**: "client and server access configuration be published this way"
- **Numeric Replies**: ERR_NOSUCHSERVER, RPL_STATSLINKINFO, RPL_STATSUPTIME, RPL_STATSCOMMANDS, RPL_STATSOLINE, RPL_ENDOFSTATS

**Changes**:
- Parameter renamed from `<server>` to `<target>`
- Reduced standard query set from 9 to 4 (removed c, h, i, k, y)
- Changed measurement from bytes to Kbytes for traffic statistics
- Changed from "must" to "SHOULD" for query support
- Removed several numeric reply types (RPL_STATSCLINE, RPL_STATSNLINE, RPL_STATSILINE, RPL_STATSKLINE, RPL_STATSQLINE, RPL_STATSLLINE, RPL_STATSHLINE)
- More flexibility for implementation-specific queries
- Simplified examples (removed the :Wiz example)

---

#### 3.4.5/4.3.3 LINKS Message

**RFC 1459**:
- **Parameters**: [[<remote server>] <server mask>]
- **Description**: "list all servers which are known by the server"
- **Matching requirement**: "must match the mask, or if no mask is given, the full list is returned"
- **Numeric Replies**: ERR_NOSUCHSERVER, RPL_LINKS, RPL_ENDOFLINKS

**RFC 2812**:
- **Parameters**: [ [ <remote server> ] <server mask> ]
- **Description**: "list all servernames, which are known by the server"
- **Matching requirement**: "MUST match the mask, or if no mask is given, the full list is returned"
- **Numeric Replies**: ERR_NOSUCHSERVER, RPL_LINKS, RPL_ENDOFLINKS

**Changes**:
- Changed "must" to "MUST" (RFC 2119 compliance)
- "servers" → "servernames" (minor clarification)
- Examples reformatted slightly (removed :WiZ prefix in second example)

---

#### 3.4.6/4.3.4 TIME Message

**RFC 1459**:
- **Parameters**: [<server>]
- **Description**: "query local time from the specified server"
- **Numeric Replies**: ERR_NOSUCHSERVER, RPL_TIME

**RFC 2812**:
- **Parameters**: [ <target> ]
- **Description**: "query local time from the specified server"
- **Wildcards**: Allowed in `<target>` parameter
- **Numeric Replies**: ERR_NOSUCHSERVER, RPL_TIME

**Changes**:
- Parameter renamed from `<server>` to `<target>`
- Wildcard support explicitly documented
- Examples reduced (removed the "Angel TIME *.au" example)

---

#### 3.4.7/4.3.5 CONNECT Message

**RFC 1459**:
- **Parameters**: <target server> [<port> [<remote server>]]
- **Port parameter**: Optional
- **Privilege**: "is to be available only to IRC Operators"
- **Numeric Replies**: ERR_NOSUCHSERVER, ERR_NOPRIVILEGES, ERR_NEEDMOREPARAMS

**RFC 2812**:
- **Parameters**: <target server> <port> [ <remote server> ]
- **Port parameter**: Required (no longer optional)
- **Privilege**: "SHOULD be available only to IRC Operators"
- **Behavior clarification**: More detailed explanation of remote server matching and forwarding
- **New requirement**: "The server receiving a remote CONNECT command SHOULD generate a WALLOPS message describing the source and target of the request"
- **Numeric Replies**: ERR_NOSUCHSERVER, ERR_NOPRIVILEGES, ERR_NEEDMOREPARAMS

**Changes**:
- Port parameter changed from optional to required
- "is to be" → "SHOULD be" (RFC 2119 compliance)
- Added requirement for WALLOPS message on remote CONNECT
- More detailed specification of remote server behavior
- Example updated to show required port parameter

---

#### 3.4.8/4.3.6 TRACE Message

**RFC 1459**:
- **Parameters**: [<server>]
- **Description**: Basic route tracing functionality
- **Behavior**: "recommended that TRACE command send a message to the sender telling which servers the current server has direct connection to"
- **User visibility**: "only operators are permitted to see users present"
- **Numeric Replies**: ERR_NOSUCHSERVER, RPL_TRACELINK, RPL_TRACECONNECTING, RPL_TRACEHANDSHAKE, RPL_TRACEUNKNOWN, RPL_TRACEOPERATOR, RPL_TRACEUSER, RPL_TRACESERVER, RPL_TRACESERVICE, RPL_TRACENEWTYPE, RPL_TRACECLASS

**RFC 2812**:
- **Parameters**: [ <target> ]
- **Description**: Enhanced with more detailed specifications
- **Behavior**: "RECOMMENDED that TRACE command sends a message to the sender telling which servers the local server has direct connection to"
- **Server reporting**: "REQUIRED to report all servers, services and operators which are connected to it"
- **User visibility**: "if the command was issued by an operator, the server MAY also report all users"
- **Services support**: Explicitly mentions services in addition to servers
- **Wildcards**: Allowed in `<target>` parameter
- **Default behavior**: "RECOMMENDED that the TRACE command is parsed as targeted to the processing server" when omitted
- **Numeric Replies**: ERR_NOSUCHSERVER, RPL_TRACELINK, RPL_TRACECONNECTING, RPL_TRACEHANDSHAKE, RPL_TRACEUNKNOWN, RPL_TRACEOPERATOR, RPL_TRACEUSER, RPL_TRACESERVER, RPL_TRACESERVICE, RPL_TRACENEWTYPE, RPL_TRACECLASS, RPL_TRACELOG, RPL_TRACEEND

**Changes**:
- Parameter renamed from `<server>` to `<target>`
- Added explicit service support
- Added RPL_TRACELOG and RPL_TRACEEND numeric replies
- More formal specification with MUST/SHOULD/MAY/REQUIRED/RECOMMENDED
- Wildcard support explicitly documented
- More detailed behavioral specifications
- Example simplified (removed :WiZ TRACE AngelDust example)

---

#### 3.4.9/4.3.7 ADMIN Command

**RFC 1459**:
- **Parameters**: [<server>]
- **Description**: "find the name of the administrator of the given server"
- **Forwarding**: "Each server must have the ability to forward ADMIN messages to other servers"
- **Numeric Replies**: ERR_NOSUCHSERVER, RPL_ADMINME, RPL_ADMINLOC1, RPL_ADMINLOC2, RPL_ADMINEMAIL

**RFC 2812**:
- **Parameters**: [ <target> ]
- **Description**: "find information about the administrator of the given server"
- **Forwarding**: "Each server MUST have the ability to forward ADMIN messages to other servers"
- **Wildcards**: Allowed in `<target>` parameter
- **Numeric Replies**: ERR_NOSUCHSERVER, RPL_ADMINME, RPL_ADMINLOC1, RPL_ADMINLOC2, RPL_ADMINEMAIL

**Changes**:
- Parameter renamed from `<server>` to `<target>`
- "name" → "information" (broader scope)
- "must" → "MUST" (RFC 2119 compliance)
- Wildcard support explicitly documented
- Second example changed from "*.edu" to "syrk" (nickname instead of server mask)

---

#### 3.4.10/4.3.8 INFO Command

**RFC 1459**:
- **Parameters**: [<server>]
- **Description**: "is required to return information which describes the server"
- **Numeric Replies**: ERR_NOSUCHSERVER, RPL_INFO, RPL_ENDOFINFO

**RFC 2812**:
- **Parameters**: [ <target> ]
- **Description**: "is REQUIRED to return information describing the server"
- **Wildcards**: Allowed in `<target>` parameter
- **Numeric Replies**: ERR_NOSUCHSERVER, RPL_INFO, RPL_ENDOFINFO

**Changes**:
- Parameter renamed from `<server>` to `<target>`
- "is required" → "is REQUIRED" (RFC 2119 compliance)
- Wildcard support explicitly documented
- Examples reduced (removed "*.fi" example)

---

## Section 1: Introduction / Labels

### Summary

RFC 1459's Section 1 "Introduction" provides a general overview of IRC as a teleconferencing system, including server network topology diagrams and detailed explanations of all components. RFC 2812's Section 1 "Labels" takes a more focused, technical approach by simply defining the identifiers used in the protocol without providing general background information. This reflects RFC 2812's nature as a client-specific protocol document rather than a comprehensive protocol overview.

### Key Differences

**What's New in RFC 2812:**
- **Services (1.2.2)**: Completely new component type introduced, distinguished by a service name composed of nickname + server name
- **Users subsection (1.2.1)**: Users explicitly separated from generic "Clients" definition
- **Channel prefixes expanded**: Added '+' and '!' as valid channel prefix characters (in addition to '&' and '#')
- **Case insensitivity**: Explicitly states channel names are case insensitive
- **Colon delimiter**: Can be used as delimiter for channel mask
- **Forward-compatibility note**: Clients SHOULD accept nicknames longer than 9 characters for future protocol evolutions
- **Character equivalence expanded**: Added ^ and ~ to the Scandinavian character mappings ({}|^ ↔ []\~)
- **Reference to external document**: Channel type definitions deferred to separate "Internet Relay Chat: Channel Management" [IRC-CHAN] document

**What Was Removed from RFC 1459:**
- **General IRC introduction**: Paragraphs explaining IRC as a "teleconferencing system" and its client-server model
- **Server network topology diagram**: Detailed spanning tree diagram showing server interconnections (Fig. 1)
- **Distributed vs local channels explanation**: Discussion of '#' (distributed) vs '&' (local) channel semantics
- **Channel operators section (1.3.1)**: Entire subsection detailing channel operator powers (KICK, MODE, INVITE, TOPIC commands) and the '@' symbol
- **Network split/healing behavior**: Detailed explanation of channel behavior during netsplits
- **Channel recommendations**: Suggestion of 10 channel limit for users

**What Was Changed/Clarified:**

1. **Section purpose and title**:
   - RFC 1459: "Introduction" - provides context and overview
   - RFC 2812: "Labels" - defines identifiers only

2. **Servers (1.1)**:
   - RFC 1459: Describes servers as "backbone" with spanning tree topology, includes network diagram
   - RFC 2812: Simply states servers are "uniquely identified by their name" with max length 63 characters

3. **Clients (1.2)**:
   - RFC 1459: Defines as "anything connecting to a server that is not another server"; lists required info (nickname max 9 chars, real hostname, username, connected server)
   - RFC 2812: Generic definition only - requires "netwide unique identifier" and introducing server; actual client types (Users/Services) defined in subsections

4. **Operators**:
   - RFC 1459 (1.2.1): States powers are "required" and "needed"
   - RFC 2812 (1.2.1.1): Softens language to "often necessary"; adds cautionary note that KILL benefits are "close to inexistent"
   - Section numbering changed from 1.2.1 to 1.2.1.1 (now under Users)
   - Reference updates: 4.1.7/4.3.5 → 3.1.8/3.4.7 (SQUIT/CONNECT); 4.6.1 → 3.7.1 (KILL)

5. **Channels (1.3)**:
   - **Length limit**: 200 characters → 50 characters
   - **Prefixes**: '&' or '#' → '&', '#', '+' or '!'
   - **Restrictions**: RFC 1459 says "may not contain"; RFC 2812 uses stronger "SHALL NOT contain"
   - **Additional restrictions**: RFC 2812 explicitly mentions colon (':') as delimiter for channel mask
   - **Case sensitivity**: RFC 2812 explicitly states "Channel names are case insensitive"
   - **Grammar reference**: RFC 2812 adds reference to section 2.3.1 for exact syntax

### Details

#### Structural Changes

The most fundamental change is the shift in purpose. RFC 1459's Introduction aimed to explain "what IRC is" to someone unfamiliar with the protocol, including conceptual descriptions like "a teleconferencing system, which (through the use of the client-server model) is well-suited to running on many machines in a distributed fashion." RFC 2812's Labels section assumes the reader already understands IRC and simply needs formal definitions of the protocol's identifiers.

This aligns with RFC 2812's scope as a client protocol specification (noted in its subtitle "Internet Relay Chat: Client Protocol") rather than a complete protocol description. The removal of server network topology details makes sense as these are more relevant to server-server protocols.

#### Introduction of Services

The addition of Services (1.2.2) is the most significant new content. Services represent automated functions that appear as special users, identified by a combination of nickname and server name. This formalization suggests services became an important part of IRC implementations between 1993 and 2000. The section notes that like users, services have a 9-character nickname limit.

#### Client Hierarchy Refinement

RFC 1459 treated "Clients" as a monolithic category (anything that's not a server). RFC 2812 creates a clearer hierarchy:
- **Clients** (generic category requiring unique identifier)
  - **Users** (distinguished by nickname)
    - **Operators** (special class of users)
  - **Services** (distinguished by nickname + server name)

This better reflects the different types of connections a server manages.

#### Channel System Evolution

The channel system shows significant evolution:

**Length Reduction (200 → 50 characters)**: This dramatic reduction suggests practical implementation experience showed 200 characters was unnecessarily large and possibly caused issues.

**Prefix Expansion ('&', '#' → '&', '#', '+', '!')**: RFC 1459 only documented two channel types:
- '#' for distributed channels known network-wide
- '&' for local channels on a single server

RFC 2812 adds '+' and '!' but notably does NOT define their meanings, instead referring readers to the separate [IRC-CHAN] document. This modularization suggests channel types became complex enough to warrant separate specification.

**Channel Operators Removed**: The detailed section about channel operators (@-prefixed users) and their commands (KICK, MODE, INVITE, TOPIC) was removed. This information was likely moved to the channel management specification or considered implementation detail rather than protocol definition.

**Case Insensitivity**: Making this explicit prevents ambiguity - implementations must treat "#Channel" and "#channel" as the same.

#### Operator Powers - Tone Shift

The description of operator KILL powers shows a notable tone change:

RFC 1459: "justification for this is delicate since its abuse is both destructive and annoying"

RFC 2812: "justification for this is very delicate since its abuse is both destructive and annoying, and its benefits close to inexistent"

The addition of "very" and "benefits close to inexistent" suggests growing community concern about KILL command abuse. Changing "required" to "often necessary" for operator powers generally also reflects a more cautious view of centralized control.

#### Character Set Evolution

Both versions note IRC's Scandinavian origins affecting character equivalence, but RFC 2812 expands the mapping:
- RFC 1459: {}| ↔ []\
- RFC 2812: {}|^ ↔ []\~

This affects nickname and channel name matching - implementations must treat these as case variants.

#### Forward Compatibility

RFC 2812 adds: "While the maximum length is limited to nine characters, clients SHOULD accept longer strings as they may become used in future evolutions of the protocol."

This guidance helps ensure implementations won't break if the nickname length limit is increased in future RFCs, showing lessons learned about protocol evolution.

#### Protocol Formalization

RFC 2812 consistently uses RFC 2119 keywords (MUST, SHOULD, SHALL NOT) where RFC 1459 used informal language. For example:
- "may not contain" → "SHALL NOT contain"
- "must be" → "MUST be"

This formalization makes requirements unambiguous for implementers.

---

## Section 4.2/3.2: Channel Operations

### Summary

RFC 2812 Section 3.2 modernizes and expands upon RFC 1459 Section 4.2's channel operations. Key improvements include: support for leaving all channels with "JOIN 0", optional part messages, formalized multiple-target KICK commands, new exception and invite list modes, topic clearing, and server targeting for NAMES/LIST. The specification also adds backward compatibility requirements and defers detailed mode semantics to a separate Channel Management document.

### Key Differences

- **JOIN**: Adds "JOIN 0" to leave all channels, new error codes (ERR_TOOMANYTARGETS, ERR_UNAVAILRESOURCE), explicit list parsing/sending requirements
- **PART**: Introduces optional part message parameter, guarantees server always grants request
- **MODE**: Separates channel modes from user modes into distinct sections, adds exception lists (+e), invite lists (+I), and creator query (O mode), references external Channel Management document
- **TOPIC**: Enables topic clearing with empty string parameter
- **NAMES**: Adds optional server targeting with wildcard support, new error codes for routing
- **LIST**: Adds optional server targeting with wildcard support, removes RPL_LISTSTART
- **INVITE**: Tightens restrictions requiring channel membership for existing channels, clarifies notification behavior
- **KICK**: Formalizes multi-channel/multi-user syntax as standard (was note in RFC 1459), adds backward compatibility requirements

### Details

#### 1. JOIN Message

**RFC 1459 (Section 4.2.1)**
- Parameters: `<channel>{,<channel>} [<key>{,<key>}]`
- Describes validation conditions in detail (invite-only, ban masks, channel keys)
- Numeric Replies: ERR_NEEDMOREPARAMS, ERR_BANNEDFROMCHAN, ERR_INVITEONLYCHAN, ERR_BADCHANNELKEY, ERR_CHANNELISFULL, ERR_BADCHANMASK, ERR_NOSUCHCHANNEL, ERR_TOOMANYCHANNELS, RPL_TOPIC

**RFC 2812 (Section 3.2.1)**
- Parameters: `( <channel> *( "," <channel> ) [ <key> *( "," <key> ) ] ) / "0"`
- **NEW**: Special "0" parameter to leave all channels (processed as PART for each channel)
- **NEW**: Servers MUST parse argument lists but SHOULD NOT send lists to clients
- **NEW**: User receives JOIN message as confirmation
- **NEW**: Additional numeric replies: ERR_TOOMANYTARGETS, ERR_UNAVAILRESOURCE
- Defers channel rules to "Internet Relay Chat: Channel Management" [IRC-CHAN] document
- Example added: `JOIN 0` to leave all currently joined channels

**Significance**: The "JOIN 0" feature provides a convenient way to reset channel membership. The formalization of list handling behavior improves interoperability between implementations.

---

#### 2. PART Message

**RFC 1459 (Section 4.2.2)**
- Parameters: `<channel>{,<channel>}`
- Simple removal from channel list
- No part message support

**RFC 2812 (Section 3.2.2)**
- Parameters: `<channel> *( "," <channel> ) [ <Part Message> ]`
- **NEW**: Optional part message parameter (sent instead of default nickname)
- **NEW**: Explicitly states "This request is always granted by the server"
- **NEW**: Servers MUST parse lists but SHOULD NOT send lists to clients
- Example added: `:WiZ!jto@tolsun.oulu.fi PART #playzone :I lost`

**Significance**: Part messages allow users to provide context when leaving channels, improving communication. The guarantee that servers always grant PART requests clarifies expected behavior.

---

#### 3. MODE Message (Channel Modes)

**RFC 1459 (Section 4.2.3)**
- Section covers both Channel modes (4.2.3.1) and User modes (4.2.3.2)
- Channel mode parameters: `<channel> {[+|-]|o|p|s|i|t|n|b|v} [<limit>] [<user>] [<ban mask>]`
- Lists specific modes: o (op), p (private), s (secret), i (invite-only), t (topic), n (no external messages), m (moderated), l (limit), b (ban), v (voice), k (key)
- Notes 3-parameter limit for 'o' and 'b' combinations
- Numeric Replies: ERR_NEEDMOREPARAMS, RPL_CHANNELMODEIS, ERR_CHANOPRIVSNEEDED, ERR_NOSUCHNICK, ERR_NOTONCHANNEL, ERR_KEYSET, RPL_BANLIST, RPL_ENDOFBANLIST, ERR_UNKNOWNMODE, ERR_NOSUCHCHANNEL, ERR_USERSDONTMATCH, RPL_UMODEIS, ERR_UMODEUNKNOWNFLAG

**RFC 2812 (Section 3.2.3)**
- Section 3.2.3 covers only "Channel mode message" (user modes separated to different section)
- Parameters: `<channel> *( ( "-" / "+" ) *<modes> *<modeparams> )`
- References "Internet Relay Chat: Channel Management" [IRC-CHAN] for mode definitions
- Maintains 3-parameter limit for modes taking parameters
- **NEW**: Numeric Replies added: ERR_NOCHANMODES, ERR_USERNOTINCHANNEL, RPL_EXCEPTLIST, RPL_ENDOFEXCEPTLIST, RPL_INVITELIST, RPL_ENDOFINVITELIST, RPL_UNIQOPIS
- **NEW**: Examples show exception lists: `MODE &oulu +b *!*@*.edu +e *!*@*.bu.edu` (ban *.edu except *.bu.edu)
- **NEW**: Examples show invite list: `MODE #meditation I` (list invitation masks)
- **NEW**: Examples show creator query: `MODE !12345ircd O` (ask who channel creator is)

**Significance**: Separation of channel and user modes improves document organization. Exception lists (+e) and invite lists (+I) provide more granular access control. Deferring mode semantics to a separate document allows independent evolution of channel management policies.

---

#### 4. TOPIC Message

**RFC 1459 (Section 4.2.4)**
- Parameters: `<channel> [<topic>]`
- View or change channel topic
- Channel modes may restrict who can change topic
- Numeric Replies: ERR_NEEDMOREPARAMS, ERR_NOTONCHANNEL, RPL_NOTOPIC, RPL_TOPIC, ERR_CHANOPRIVSNEEDED

**RFC 2812 (Section 3.2.4)**
- Parameters: `<channel> [ <topic> ]`
- **NEW**: If topic parameter is empty string, topic is removed
- **NEW**: Numeric Reply added: ERR_NOCHANMODES
- Example added: `TOPIC #test :` (clear the topic on #test)

**Significance**: Ability to clear topics with empty string provides explicit mechanism for topic removal, rather than relying on implementation-specific behavior.

---

#### 5. NAMES Message

**RFC 1459 (Section 4.2.5)**
- Parameters: `[<channel>{,<channel>}]`
- Lists visible nicknames on channels
- Describes visibility rules directly (private +p, secret +s channels)
- Returns users not on visible channels as being on "*"
- Numerics: RPL_NAMREPLY, RPL_ENDOFNAMES

**RFC 2812 (Section 3.2.5)**
- Parameters: `[ <channel> *( "," <channel> ) [ <target> ] ]`
- **NEW**: Optional `<target>` parameter to forward request to specific server
- **NEW**: Wildcards allowed in `<target>` parameter
- **NEW**: Numeric Replies added: ERR_TOOMANYMATCHES, ERR_NOSUCHSERVER
- References "Internet Relay Chat: Channel Management" [IRC-CHAN] for visibility rules
- Maintains "*" channel for users not on visible channels

**Significance**: Server targeting enables querying channel membership on remote servers, useful for distributed network management and debugging.

---

#### 6. LIST Message

**RFC 1459 (Section 4.2.6)**
- Parameters: `[<channel>{,<channel>} [<server>]]`
- Lists channels and topics
- Describes private channel listing as "Prv" without topics
- Secret channels not listed unless client is member
- Numeric Replies: ERR_NOSUCHSERVER, RPL_LISTSTART, RPL_LIST, RPL_LISTEND

**RFC 2812 (Section 3.2.6)**
- Parameters: `[ <channel> *( "," <channel> ) [ <target> ] ]`
- **NEW**: Optional `<target>` parameter to forward request to specific server
- **NEW**: Wildcards allowed in `<target>` parameter
- **NEW**: Numeric Replies added: ERR_TOOMANYMATCHES, ERR_NOSUCHSERVER
- **REMOVED**: RPL_LISTSTART numeric reply
- Does not describe private/secret channel behavior (deferred to implementation)

**Significance**: Server targeting enables listing channels on remote servers. Removal of RPL_LISTSTART simplifies the protocol (many implementations didn't use it consistently).

---

#### 7. INVITE Message

**RFC 1459 (Section 4.2.7)**
- Parameters: `<nickname> <channel>`
- Invite user to channel (channel doesn't need to exist)
- Channel operator required only for invite-only channels (+i)
- Numeric Replies: ERR_NEEDMOREPARAMS, ERR_NOSUCHNICK, ERR_NOTONCHANNEL, ERR_USERONCHANNEL, ERR_CHANOPRIVSNEEDED, RPL_INVITING, RPL_AWAY

**RFC 2812 (Section 3.2.7)**
- Parameters: `<nickname> <channel>`
- **NEW**: If channel exists, only members can invite others
- **NEW**: Clarifies that for invite-only channels, only channel operators may INVITE
- **NEW**: Explicit notification behavior: "Only the user inviting and the user being invited will receive notification of the invitation. Other channel members are not notified."
- Same numeric replies

**Significance**: Tighter restrictions prevent invitation spam to existing channels from non-members. Clarification of notification behavior addresses implementation inconsistencies and user confusion.

---

#### 8. KICK Command

**RFC 1459 (Section 4.2.8)**
- Parameters: `<channel> <user> [<comment>]`
- Forcibly remove user from channel
- Only channel operators may kick
- Numeric Replies: ERR_NEEDMOREPARAMS, ERR_NOSUCHCHANNEL, ERR_BADCHANMASK, ERR_CHANOPRIVSNEEDED, ERR_NOTONCHANNEL
- **NOTE** at end suggests possible extension: `<channel>{,<channel>} <user>{,<user>} [<comment>]`

**RFC 2812 (Section 3.2.8)**
- Parameters: `<channel> *( "," <channel> ) <user> *( "," <user> ) [<comment>]`
- **NEW**: Formalizes multi-channel/multi-user syntax (implements RFC 1459's suggested extension)
- **NEW**: Constraint: "there MUST be either one channel parameter and multiple user parameter, or as many channel parameters as there are user parameters"
- **NEW**: Backward compatibility requirement: "The server MUST NOT send KICK messages with multiple channels or users to clients"
- **NEW**: Numeric Reply added: ERR_USERNOTINCHANNEL
- Default comment changed from unspecified to "the nickname of the user issuing the KICK"

**Significance**: Multi-target KICK syntax improves efficiency for mass user removal. Backward compatibility requirement ensures old clients don't break when receiving KICK messages.

---


## Section 4.6/3.7: Miscellaneous Messages

### Summary

RFC 2812 Section 3.7 significantly refines the Miscellaneous messages from RFC 1459 Section 4.6, introducing stronger normative language (MUST/SHOULD/MAY), clarifying ambiguities, addressing abuse scenarios, and expanding protocol documentation. The four message types (KILL, PING, PONG, ERROR) maintain the same core functionality but with important behavioral and implementation clarifications.

### Key Differences

- **Normative Language**: RFC 2812 consistently uses RFC 2119 keywords (MUST, SHOULD, MAY) instead of RFC 1459's informal "must", "should", "may"
- **KILL Message Enhancements**: Added nickname delay mechanism to prevent "KILL loops" and expanded discussion of abuse scenarios
- **PING/PONG Clarifications**: Removed ambiguous guidance about servers not responding to PINGs; clarified that both clients and servers must respond
- **Parameter Terminology**: Changed "daemon" to "server" in PONG message for consistency
- **ERROR Message Scope**: Added explicit use case for client connection termination
- **Abuse Prevention**: Enhanced focus on preventing abusive behavior and fake messages

### Details

#### 4.6.1/3.7.1: KILL Message

**Availability and Purpose:**
- RFC 1459: "KILL is used by servers when they encounter a duplicate entry in the list of valid nicknames and is used to remove both entries. It is also available to operators."
- RFC 2812: "Servers generate KILL messages on nickname collisions. It MAY also be available to users who have the operator status."
  - *Changes*: More precise language about server-generated KILLs; uses MAY for operator availability

**Abuse Discussion:**
- RFC 1459: Incomplete sentence fragment: "of being abused, any user may elect to receive KILL messages..."
- RFC 2812: Complete discussion: "of 'flooding' from abusive users or accidents. Abusive users usually don't care as they will reconnect promptly and resume their abusive behaviour. To prevent this command from being abused, any user may elect to receive KILL messages..."
  - *Changes*: Fixed sentence fragment; added context about abusive user behavior

**Nickname Delay Mechanism (New in RFC 2812):**
- RFC 2812 adds entire paragraph: "When a client is removed as the result of a KILL message, the server SHOULD add the nickname to the list of unavailable nicknames in an attempt to avoid clients to reuse this name immediately which is usually the pattern of abusive behaviour often leading to useless 'KILL loops'. See the 'IRC Server Protocol' document [IRC-SERVER] for more information on this procedure."
  - *Significance*: Introduces anti-abuse mechanism to prevent rapid nickname reuse and KILL loops

**Comment Requirements:**
- RFC 1459: "The comment given must reflect the actual reason for the KILL."
- RFC 2812: "The comment given MUST reflect the actual reason for the KILL."
  - *Changes*: Strengthened to normative requirement (MUST)

**Operator Restrictions:**
- RFC 1459 NOTE: "It is recommended that only Operators be allowed to kill other users with KILL message. In an ideal world not even operators would need to do this and it would be left to servers to deal with."
- RFC 2812 NOTE: "It is RECOMMENDED that only Operators be allowed to kill other users with KILL command. This command has been the subject of many controversies over the years, and along with the above recommendation, it is also widely recognized that not even operators should be allowed to kill users on remote servers."
  - *Changes*: Upgraded to RECOMMENDED; added historical context about controversies; added specific guidance against remote server kills

#### 4.6.2/3.7.2: PING Message

**Scope:**
- RFC 1459: "The PING message is used to test the presence of an active client at the other end of the connection."
- RFC 2812: "The PING command is used to test the presence of an active client or server at the other end of the connection."
  - *Changes*: Explicitly includes servers as potential targets

**Sender Clarification:**
- RFC 1459: "A PING message is sent at regular intervals..."
- RFC 2812: "Servers send a PING message at regular intervals..."
  - *Changes*: Explicitly identifies servers as the sender of regular PINGs

**Active Connection Pings (New in RFC 2812):**
- RFC 2812 adds: "A PING message MAY be sent even if the connection is active."
  - *Significance*: Clarifies that PINGs aren't only for idle connections

**Response Requirements:**
- RFC 1459: "Any client which receives a PING message must respond to <server1> (server which sent the PING message out) as quickly as possible with an appropriate PONG message to indicate it is still there and alive. Servers should not respond to PING commands but rely on PINGs from the other end of the connection to indicate the connection is alive."
- RFC 2812: "When a PING message is received, the appropriate PONG message MUST be sent as reply to <server1> (server which sent the PING message out) as soon as possible."
  - *Changes*: Upgraded to MUST; removed confusing guidance about servers not responding; simplified to apply to all recipients

**Server2 Parameter:**
- RFC 1459: "If the <server2> parameter is specified, the PING message gets forwarded there."
- RFC 2812: "If the <server2> parameter is specified, it represents the target of the ping, and the message gets forwarded there."
  - *Changes*: Added clarification that server2 is the target

**Examples:**
- RFC 1459 provides 2 examples:
  1. `PING tolsun.oulu.fi` - server sending PING to another server
  2. `PING WiZ` - PING message being sent to nick WiZ
- RFC 2812 provides 3 examples:
  1. `PING tolsun.oulu.fi` - Command to send a PING message to server
  2. `PING WiZ tolsun.oulu.fi` - Command from WiZ to send a PING message to server "tolsun.oulu.fi"
  3. `PING :irc.funet.fi` - Ping message sent by server "irc.funet.fi"
  - *Changes*: Added third example showing server-sent PING; second example now includes server2 parameter

#### 4.6.3/3.7.3: PONG Message

**Parameter Terminology:**
- RFC 1459: `Parameters: <daemon> [<daemon2>]`
- RFC 2812: `Parameters: <server> [ <server2> ]`
  - *Changes*: Modernized terminology from "daemon" to "server"

**Description:**
- RFC 1459: "PONG message is a reply to ping message. If parameter <daemon2> is given this message must be forwarded to given daemon. The <daemon> parameter is the name of the daemon who has responded to PING message and generated this message."
- RFC 2812: "PONG message is a reply to ping message. If parameter <server2> is given, this message MUST be forwarded to given target. The <server> parameter is the name of the entity who has responded to PING message and generated this message."
  - *Changes*: Changed "daemon" to "server"/"entity"; upgraded "must" to MUST; changed "given daemon" to "given target"

**Examples:**
- Both RFCs show the same example but RFC 1459's example was split across pages 36-37, while RFC 2812 shows it on a single page

#### 4.6.4/3.7.4: ERROR Message

**Purpose and Audience:**
- RFC 1459: "The ERROR command is for use by servers when reporting a serious or fatal error to its operators."
- RFC 2812: "The ERROR command is for use by servers when reporting a serious or fatal error to its peers."
  - *Changes*: Changed "operators" to "peers" - more accurately describes server-to-server communication

**Client Acceptance:**
- RFC 1459: "It may also be sent from one server to another but must not be accepted from any normal unknown clients."
- RFC 2812: "It may also be sent from one server to another but MUST NOT be accepted from any normal unknown clients."
  - *Changes*: Upgraded "must not" to MUST NOT

**Usage Scope:**
- RFC 1459: "An ERROR message is for use for reporting errors which occur with a server-to-server link only. An ERROR message is sent to the server at the other end (which sends it to all of its connected operators) and to all operators currently connected."
- RFC 2812: "Only an ERROR message SHOULD be used for reporting errors which occur with a server-to-server link. An ERROR message is sent to the server at the other end (which reports it to appropriate local users and logs) and to appropriate local users and logs."
  - *Changes*: Added SHOULD; changed "all connected operators" to "appropriate local users and logs" (broader audience); improved clarity about logging

**Client Connection Termination (New in RFC 2812):**
- RFC 2812 adds: "The ERROR message is also used before terminating a client connection."
  - *Significance*: Documents additional use case beyond server-to-server errors

**NOTICE Encapsulation:**
- RFC 1459: "When a server sends a received ERROR message to its operators, the message should be encapsulated inside a NOTICE message, indicating that the client was not responsible for the error."
- RFC 2812: "When a server sends a received ERROR message to its operators, the message SHOULD be encapsulated inside a NOTICE message, indicating that the client was not responsible for the error."
  - *Changes*: Upgraded "should" to SHOULD

**Examples:**
- Both RFCs show identical examples with minor formatting differences

---

## Section 6/5: Replies

### Summary

RFC 1459 Section 6 and RFC 2812 Section 5 both document numeric replies used in IRC client-server communication. These sections cover error replies (400-599), command responses (200-399), and reserved numerics. RFC 2812 introduces significant organizational changes, adds 23 new numeric replies, obsoletes or moves several to reserved status, and improves message formats and descriptions throughout.

### Key Differences

- **Structural Reordering**: RFC 1459 presents Error Replies first (6.1), then Command Responses (6.2). RFC 2812 reverses this order, presenting Command Responses first (5.1), then Error Replies (5.2).

- **Welcome Messages Documented**: RFC 2812 explicitly documents the connection registration replies (001-004: RPL_WELCOME, RPL_YOURHOST, RPL_CREATED, RPL_MYINFO) in Section 5.1, which were used but not fully documented in RFC 1459's Section 6.

- **Service Protocol Support**: RFC 2812 adds multiple numerics for service protocol support (207 RPL_TRACESERVICE, 234/235 RPL_SERVLIST/RPL_SERVLISTEND, 383 RPL_YOURESERVICE, 408 ERR_NOSUCHSERVICE).

- **Enhanced Channel Management**: New numerics for invite lists (346/347), exception lists (348/349), and channel creator privileges (325 RPL_UNIQOPIS, 485 ERR_UNIQOPPRIVSNEEDED) provide more granular channel control.

- **Server Statistics Moved**: Most RPL_STATS* numerics (213-218, 241, 244) moved from documented to reserved section, indicating these are server-specific implementation details.

- **Improved Error Handling**: New error codes for edge cases (415 ERR_BADMASK, 437 ERR_UNAVAILRESOURCE, 477 ERR_NOCHANMODES, 478 ERR_BANLISTFULL, 484 ERR_RESTRICTED) and rate limiting (263 RPL_TRYAGAIN).

### New Numeric Replies in RFC 2812

**Command Responses (001-399):**

- **005 RPL_BOUNCE**: "Try server <server name>, port <port number>" - Suggests alternative server when connection refused (often when server is full)

- **207 RPL_TRACESERVICE**: "Service <class> <name> <type> <active type>" - Added for TRACE responses involving services

- **209 RPL_TRACECLASS**: "Class <class> <count>" - Promoted from reserved to documented for TRACE class information

- **210 RPL_TRACERECONNECT**: "Unused" - Reserved for future reconnection tracking

- **234 RPL_SERVLIST**: "<name> <server> <mask> <type> <hopcount> <info>" - Promoted from reserved, lists services matching SERVLIST query

- **235 RPL_SERVLISTEND**: "<mask> <type> :End of service listing" - Promoted from reserved, marks end of SERVLIST response

- **262 RPL_TRACEEND**: "<server name> <version & debug level> :End of TRACE" - Explicitly marks end of TRACE output

- **263 RPL_TRYAGAIN**: "<command> :Please wait a while and try again." - Server dropping command without processing, client should retry later

- **325 RPL_UNIQOPIS**: "<channel> <nickname>" - Identifies the original channel creator (for unique channel operator privileges)

- **346 RPL_INVITELIST**: "<channel> <invitemask>" - Lists channel invitation exception masks

- **347 RPL_ENDOFINVITELIST**: "<channel> :End of channel invite list" - Marks end of invitation list

- **348 RPL_EXCEPTLIST**: "<channel> <exceptionmask>" - Lists channel ban exception masks

- **349 RPL_ENDOFEXCEPTLIST**: "<channel> :End of channel exception list" - Marks end of exception list

- **383 RPL_YOURESERVICE**: "You are service <servicename>" - Sent to service upon successful registration

**Error Replies (400-599):**

- **408 ERR_NOSUCHSERVICE**: "<service name> :No such service" - Returned when SQUERY targets non-existent service

- **415 ERR_BADMASK**: "<mask> :Bad Server/host mask" - Validates server/host mask format in PRIVMSG

- **437 ERR_UNAVAILRESOURCE**: "<nick/channel> :Nick/channel is temporarily unavailable" - Channel/nick blocked by delay mechanism (anti-abuse)

- **466 ERR_YOUWILLBEBANNED**: (no format specified) - Promoted from reserved, warns user of impending ban

- **476 ERR_BADCHANMASK**: "<channel> :Bad Channel Mask" - Promoted from reserved, validates channel name format

- **477 ERR_NOCHANMODES**: "<channel> :Channel doesn't support modes" - Channel type doesn't support mode changes

- **478 ERR_BANLISTFULL**: "<channel> <char> :Channel list is full" - Ban list (or similar list) reached maximum size

- **484 ERR_RESTRICTED**: ":Your connection is restricted!" - User has restricted connection (user mode +r)

- **485 ERR_UNIQOPPRIVSNEEDED**: ":You're not the original channel operator" - MODE command requires original channel creator privileges

### Removed/Changed Replies

**Obsoleted:**

- **321 RPL_LISTSTART**: Changed from "Channel :Users  Name" to "Obsolete. Not used." - RFC 2812 marks this as no longer necessary; LIST responses now start directly with RPL_LIST.

**Moved to Reserved (documented in RFC 1459, reserved in RFC 2812):**

- **300 RPL_NONE**: "Dummy reply number. Not used." - Moved to reserved section (listed alongside 316, 361-363, 373, 384)

- **213 RPL_STATSCLINE**: "C <host> * <name> <port> <class>" - Server config line for remote servers, moved to reserved

- **214 RPL_STATSNLINE**: "N <host> * <name> <port> <class>" - Server config line for allowed server connections, moved to reserved

- **215 RPL_STATSILINE**: "I <host> * <host> <port> <class>" - Server config line for allowed client connections, moved to reserved

- **216 RPL_STATSKLINE**: "K <host> * <username> <port> <class>" - Server config line for banned users, moved to reserved

- **218 RPL_STATSYLINE**: "Y <class> <ping frequency> <connect frequency> <max sendq>" - Server connection class config, moved to reserved

- **241 RPL_STATSLLINE**: "L <hostmask> * <servername> <maxdepth>" - Server leaf connection config, moved to reserved

- **244 RPL_STATSHLINE**: "H <hostmask> * <servername>" - Server hub config, moved to reserved

**Format/Content Changes:**

- **393 RPL_USERS**: Changed from "%-8s %-9s %-8s" (printf-style format) to ":<username> <ttyline> <hostname>" (explicit IRC message format)

- **407 ERR_TOOMANYTARGETS**: RFC 1459: "<target> :Duplicate recipients. No message delivered" (one use case). RFC 2812: "<target> :<error code> recipients. <abort message>" with three use cases: duplicate recipients, too many recipients, or multiple safe channels with same shortname.

- **432 ERR_ERRONEUSNICKNAME**: Fixed typo from "Erroneus nickname" to "Erroneous nickname"

- **436 ERR_NICKCOLLISION**: RFC 1459: "<nick> :Nickname collision KILL". RFC 2812: "<nick> :Nickname collision KILL from <user>@<host>" (adds source information)

- **462 ERR_ALREADYREGISTRED**: RFC 1459: ":You may not reregister". RFC 2812: ":Unauthorized command (already registered)" (clarifies it's a command authorization issue)

- **472 ERR_UNKNOWNMODE**: RFC 1459: "<char> :is unknown mode char to me". RFC 2812: "<char> :is unknown mode char to me for <channel>" (explicitly includes channel context)

- **483 ERR_CANTKILLSERVER**: Grammar fix from "You cant kill a server!" to "You can't kill a server!"

- **211 RPL_STATSLINKINFO**: RFC 1459: "<sent bytes> <received bytes>" (raw bytes). RFC 2812: "<sent Kbytes> <received Kbytes>" (changed to kilobytes for better readability with large values)

- **212 RPL_STATSCOMMANDS**: RFC 1459: "<command> <count>". RFC 2812: "<command> <count> <byte count> <remote count>" (added byte usage and remote command tracking)

- **200 RPL_TRACELINK**: RFC 1459: "Link <version & debug level> <destination> <next server>". RFC 2812: Expanded to include "V<protocol version> <link uptime in seconds> <backstream sendq> <upstream sendq>" (adds protocol version and queue stats)

- **206 RPL_TRACESERVER**: RFC 1459: "Serv <class> <int>S <int>C <server> <nick!user|*!*>@<host|server>". RFC 2812: Adds "V<protocol version>" (protocol version tracking)

- **251 RPL_LUSERCLIENT**: RFC 1459: ":There are <integer> users and <integer> invisible on <integer> servers". RFC 2812: ":There are <integer> users and <integer> services on <integer> servers" (changed "invisible" to "services" reflecting the addition of IRC services)

- **257 RPL_ADMINLOC1 / 258 RPL_ADMINLOC2**: RFC 1459 description mentioned "university and department". RFC 2812 generalizes to "institution" (recognizes IRC servers aren't limited to academic settings)

**Stricter Language:**

RFC 2812 changes many instances of "should" to "MUST" throughout, making requirements more explicit per RFC 2119 conventions. Examples:

- **445 ERR_SUMMONDISABLED**: RFC 1459: "Must be returned by any server which does not implement it". RFC 2812: "MUST be returned by any server which doesn't implement it."

- **451 ERR_NOTREGISTERED**: RFC 2812 adds: "client MUST be registered before the server will allow it to be parsed in detail" (emphasis on requirement)

### Details

**Section Organization:**

- **RFC 1459 Section 6** (pages 42-56):
  - 6.1 Error Replies (401-502)
  - 6.2 Command Responses (200-395)
  - 6.3 Reserved Numerics

- **RFC 2812 Section 5** (pages 42-60):
  - 5.1 Command Responses (001-395)
  - 5.2 Error Replies (401-502)
  - 5.3 Reserved Numerics

**Range Definitions:**

- **RFC 2812 explicitly documents numeric ranges**: "Numerics in the range from 001 to 099 are used for client-server connections only and should never travel between servers. Replies generated in the response to commands are found in the range from 200 to 399." (lines 2388-2391)

- **Error reply range**: "Error replies are found in the range from 400 to 599." (line 2932)

These range definitions were implied in RFC 1459 but are explicitly stated in RFC 2812.

**Reserved Numerics Changes:**

RFC 1459 lists these as reserved:
```
209 RPL_TRACECLASS      217 RPL_STATSQLINE
231 RPL_SERVICEINFO     232 RPL_ENDOFSERVICES
233 RPL_SERVICE         234 RPL_SERVLIST
235 RPL_SERVLISTEND
316 RPL_WHOISCHANOP     361 RPL_KILLDONE
362 RPL_CLOSING         363 RPL_CLOSEEND
373 RPL_INFOSTART       384 RPL_MYPORTIS
466 ERR_YOUWILLBEBANNED 476 ERR_BADCHANMASK
492 ERR_NOSERVICEHOST
```

RFC 2812 lists these as reserved:
```
231 RPL_SERVICEINFO     232 RPL_ENDOFSERVICES
233 RPL_SERVICE         300 RPL_NONE
316 RPL_WHOISCHANOP     361 RPL_KILLDONE
362 RPL_CLOSING         363 RPL_CLOSEEND
373 RPL_INFOSTART       384 RPL_MYPORTIS

213 RPL_STATSCLINE      214 RPL_STATSNLINE
215 RPL_STATSILINE      216 RPL_STATSKLINE
217 RPL_STATSQLINE      218 RPL_STATSYLINE
240 RPL_STATSVLINE      241 RPL_STATSLLINE
244 RPL_STATSHLINE      244 RPL_STATSSLINE
246 RPL_STATSPING       247 RPL_STATSBLINE
250 RPL_STATSDLINE

492 ERR_NOSERVICEHOST
```

**Promoted from reserved to documented:**
- 209 RPL_TRACECLASS
- 234 RPL_SERVLIST
- 235 RPL_SERVLISTEND
- 466 ERR_YOUWILLBEBANNED
- 476 ERR_BADCHANMASK

**Added to reserved:**
- 213-218 (STATS configuration numerics)
- 240, 241, 244, 246, 247, 250 (more STATS numerics)
- 300 RPL_NONE

**Channel Mode and List Management:**

RFC 2812's addition of invite lists (346/347) and exception lists (348/349) reflects the evolution of channel management beyond simple ban lists. These allow more sophisticated access control:

- **Invite lists** (mode +I): Exceptions to invite-only channels
- **Exception lists** (mode +e): Exceptions to ban masks

Combined with the existing ban list (367/368), channels now have three complementary access control lists.

**Service Protocol Integration:**

The addition of service-related numerics (207, 234, 235, 383, 408) indicates RFC 2812's formal integration of the IRC service protocol, which was being developed in parallel. Services (like NickServ, ChanServ) are no longer treated as regular clients but have dedicated protocol support.

**Anti-Abuse Mechanisms:**

Several new replies support anti-abuse features:

- **263 RPL_TRYAGAIN**: Rate limiting at protocol level
- **437 ERR_UNAVAILRESOURCE**: Nick/channel delay mechanism to prevent rapid cycling
- **478 ERR_BANLISTFULL**: Prevents ban list flooding
- **466 ERR_YOUWILLBEBANNED**: Proactive warning before automatic ban

**Clarity Improvements:**

Beyond new numerics, RFC 2812 improves descriptions:

- More precise grammar ("can't" vs "cant")
- Corrected spelling ("Erroneous" vs "Erroneus")
- More detailed format specifications (showing protocol versions, queue states)
- Explicit MUST/SHOULD/MAY language per RFC 2119

**Implementation Notes:**

RFC 1459 (line 3132-3133): "The only current implementation of this protocol is the IRC server, version 2.8."

RFC 2812 (line 3335-3340): "The IRC software, version 2.10 is the only complete implementation of the IRC protocol (client and server). Because of the small amount of changes in the client protocol since the publication of RFC 1459 [IRC], implementations that follow it are likely to be compliant with this protocol or to require a small amount of changes to reach compliance."

This indicates RFC 2812 is largely backward compatible with RFC 1459 clients.

---


## Sections 7-8/6-7: Implementation Details & Current Problems

### Summary
RFC 1459's extensive implementation guidance (Sections 7-8, pages 56-65) was almost entirely removed in RFC 2812. RFC 1459 Section 7 covered authentication mechanisms, while Section 8 provided detailed implementation details for server developers covering TCP networking, command parsing, message delivery, connection management, configuration files, and more. In contrast, RFC 2812 Section 6 is a brief statement about current implementations, and Section 7 focuses narrowly on three specific problems (nicknames, wildcard limitations, security) rather than the comprehensive problem analysis found in RFC 1459 Section 9.

### Key Differences

**Structure:**
- **RFC 1459**: Section 7 (Authentication) + Section 8 (Implementation Details, 9+ pages) + Section 9 (Current Problems)
- **RFC 2812**: Section 6 (Current Implementations, ~10 lines) + Section 7 (Current Problems, ~20 lines)

**Content shift:**
- RFC 1459 provided extensive implementation guidance for server developers
- RFC 2812 assumes implementation knowledge is obtained from actual software (version 2.10) and from the separate Server Protocol specification (RFC 2813)
- RFC 1459's Section 9 "Current Problems" discussed scalability, labels (nicknames, channels, servers), and algorithms
- RFC 2812's Section 7 "Current Problems" narrowed focus to just three issues: nicknames, wildcard limitations, and security

**Material removed:**
- All authentication details (IP/hostname lookups, password checks, IDENT)
- All implementation guidance (TCP, Unix sockets, parsing, message delivery, flood control, non-blocking I/O, configuration files)
- Problem discussions about scalability, channel/server labels, and algorithmic concerns

**Material added:**
- New problem identified: "Limitation of wildcards" (inability to escape the backslash character)

### RFC 1459 Implementation Details (removed in RFC 2812)

**Section 7: Client and server authentication**
- IP number to hostname lookup (with reverse check) for all connections
- Password-based authentication for client and server connections
- Username verification via authentication servers (IDENT/RFC 1413)
- Strong recommendation to use passwords on inter-server connections

**Section 8: Current implementations** (pages 56-65)
Comprehensive implementation guidance covering:

**8.1 Network protocol: TCP**
- Rationale for using TCP as reliable network protocol
- Discussion of multicast IP as alternative (not widely available at the time)

**8.1.1 Support of Unix sockets**
- Configuration to accept connections on Unix domain sockets
- Recognition of sockets starting with '/' as Unix domain paths
- Hostname substitution requirements for Unix socket connections

**8.2 Command Parsing**
- Private input buffer design (512 bytes per connection)
- Non-buffered network I/O implementation
- Parsing after every read operation
- Handling multiple messages in buffer with care for client removal

**8.3 Message delivery**
- "Send queue" as FIFO queue for outgoing data
- Queue management for saturated network links
- Typical queue sizes (up to 200 Kbytes on slow connections)
- Polling strategy: read/parse all input first, then send queued data
- Reduction of write() system calls and TCP packet optimization

**8.4 Connection 'Liveness'**
- Ping mechanism to detect dead/unresponsive connections
- Timeout-based connection closure
- Sendq overflow handling (close slow connections rather than block server)

**8.5 Establishing a server to client connection**
- MOTD (Message of the Day) delivery
- LUSER command for current user/server count
- Server name/version announcement
- New user information broadcast (NICK followed by USER)
- DNS/authentication server integration

**8.6 Establishing a server-server connection**
- PASS/SERVER pair exchange and validation
- Authentication verification before accepting connection
- Race condition considerations

**8.6.1 Server exchange of state information when connecting**
- Ordered state synchronization: servers first, then users, then channels
- SERVER messages for server information
- NICK/USER/MODE/JOIN messages for user information
- MODE messages for channel information
- Explicit note: channel topics NOT exchanged (TOPIC overwrites)
- Collision detection strategy (server collisions before nickname collisions)
- Network split detection via collision location

**8.7 Terminating server-client connections**
- QUIT message generation on behalf of disconnected clients
- No other messages to be generated

**8.8 Terminating server-server connections**
- Network update requirements for both SQUIT and natural closures
- SQUIT list generation (one per server behind connection)
- QUIT list generation (one per client behind connection)

**8.9 Tracking nickname changes**
- History requirement for recent nickname changes
- Race condition mitigation for KILL, MODE (+/- o,v), and KICK commands
- Nickname existence checking and history tracing
- Time range recommendations for change traces
- Storage sizing considerations (previous nickname for every known client)

**8.10 Flood control of clients**
- Built-in server-side flood protection (not client responsibility)
- Message timer algorithm:
  - Set timer to current time if behind
  - Read all present data
  - Parse messages while timer < 10 seconds ahead
  - 2-second penalty per message
- Result: clients can send 1 message per 2 seconds without adverse effects
- Services exempted from flood control

**8.11 Non-blocking lookups**
- Real-time service requirement (minimize waiting)
- Non-blocking I/O for all network operations
- Short timeouts for disk operations

**8.11.1 Hostname (DNS) lookups**
- Custom DNS routines replacing Berkeley resolver libraries
- Non-blocking I/O operations
- Polling integration with main server I/O loop
- Avoidance of timeout delays from standard libraries

**8.11.2 Username (Ident) lookups**
- Custom ident routines replacing synchronous libraries
- Non-blocking I/O implementation
- Cooperation with main server loop

**8.12 Configuration File**
Recommended configuration file capabilities:

**8.12.1 Allowing clients to connect**
- Access control list (ACL) read at startup
- Both 'deny' and 'allow' implementations for host access control

**8.12.2 Operators**
- Two-password requirement for operator privileges
- Storage in configuration files (preferred over hard-coding)
- Crypted password format using crypt(3)
- Protection against privilege abuse and password theft

**8.12.3 Allowing servers to connect**
- Server connection whitelist (bidirectional)
- No arbitrary host connections allowed
- Password and link characteristics storage
- Prevention of improper server interconnections

**8.12.4 Administrivia**
- Administrator details for ADMIN command responses
- Server location information (university, city/state, company)
- Responsible party contact (email address)
- Hostname formats: both domain names and dot notation (127.0.0.1)
- Password specifications for incoming/outgoing connections

**Additional configuration options:**
- Server introduction restrictions
- Server branch depth limits
- Client connection time windows

**8.13 Channel membership**
- Limit: 10 channels per local user
- No limit for non-local users (consistency across network)

### RFC 2812 Current Problems (new)

**Section 6: Current implementations** (page 60)
Brief statement noting:
- IRC software version 2.10 as the only complete implementation
- Small amount of changes in client protocol since RFC 1459
- Likely compliance of RFC 1459 implementations with RFC 2812
- Expectation that minimal changes required to reach compliance

**Section 7: Current problems** (pages 60-61)
Acknowledgment that the protocol has "almost not evolved since the publication of RFC 1459" due to backward compatibility requirements. Three specific problems identified:

**7.1 Nicknames**
- Finite nickname space limitation
- Multiple users wanting same nickname
- Resolution via failure or server KILL (reference to Section 3.7.1)
- Note: This is copied from RFC 1459 Section 9.2.1 but significantly shortened

**7.2 Limitation of wildcards** (NEW in RFC 2812)
- No way to escape the backslash escape character (%x5C)
- Makes it impossible to form masks with backslash preceding wildcard
- Usually not a problem, but represents a protocol limitation

**7.3 Security considerations**
- Brief reference to separate "IRC Server Protocol" [IRC-SERVER] document
- Security issues primarily server-side concerns
- Acknowledgment that client protocol has security implications but details elsewhere

**What was removed from RFC 1459's problem discussion:**
- **9.1 Scalability**: All servers knowing all other servers/users, update propagation overhead, low server count requirements
- **9.2 Labels**: General label collision problems across nicknames, channels, and servers
- **9.2.2 Channels**: Privacy concerns, non-scaling global channel knowledge, inclusive collision handling
- **9.2.3 Servers**: Global server knowledge requirements, mask hiding
- **9.3 Algorithms**: N^2 algorithm concerns, lack of database consistency checks, race conditions from non-unique labels

**Interpretation:**
The removal of scalability and algorithmic problem discussions suggests either:
1. These issues were considered server protocol concerns moved to RFC 2813
2. They were deemed unsolvable within backward compatibility constraints
3. They were accepted as inherent limitations not requiring documentation in a standards document

The addition of the wildcard limitation shows RFC 2812 documented a specific technical limitation not previously highlighted in RFC 1459.

---


## RFC 2810: Architecture Document

### Overview

RFC 2810 "Internet Relay Chat: Architecture" (April 2000) represents a fundamental restructuring of the IRC specification family. Unlike RFC 1459, which was a monolithic document covering all aspects of IRC, RFC 2810 is the first of a new four-document suite (RFC 2810-2813) that formally separates architectural concepts from protocol implementation details.

**Purpose:** RFC 2810 specifically focuses on the high-level architecture and design philosophy of IRC, establishing the foundational concepts that the other three documents build upon. It does not define protocol commands or message formats - instead, it documents the client-server model, network topology, and service abstractions that make IRC work.

**Document Family Position:**
- RFC 2810: Architecture (this document)
- RFC 2811: Channel Management
- RFC 2812: Client Protocol
- RFC 2813: Server Protocol

### Sections 1-4: Components, Architecture, Protocol Services

#### Comparison with RFC 1459

**Structural Evolution:**

RFC 1459 Section 1 presented architectural concepts intermixed with implementation details across subsections 1.1-1.3.1 (Servers, Clients, Operators, Channels, Channel Operators). RFC 2810 separates these concerns into a dedicated architecture document with clearer component definitions and service abstractions.

**Major Conceptual Shifts:**

1. **Formalized Component Model (RFC 2810 Section 2)**
   - RFC 1459: Described components implicitly through their behavior
   - RFC 2810: Explicitly defines component types with clear boundaries:
     - Servers (2.1): "forms the backbone of IRC"
     - Clients (2.2): "anything connecting to a server that is not another server"
     - User Clients (2.2.1): Human-operated chat interfaces
     - Service Clients (2.2.2): Automated services with limited chat access

2. **Service Clients - New Concept**
   - RFC 1459: Only recognized "Operators" (1.2.1) as a special client class
   - RFC 2810: Introduces "Service Clients" (2.2.2) as a distinct component type
   - Evolution: From human operators with network privileges to automated services as first-class architectural components
   - Purpose: Services are "typically automatons used to provide some kind of service (not necessarily related to IRC itself) to users"
   - Example given: Statistics collection service
   - Technical distinction: "not intended to be used manually nor for talking" with "more limited access to chat functions" but "optionally having access to more private data from servers"

3. **Network Architecture Formalization (RFC 2810 Section 3)**
   - RFC 1459 (1.1): Mentioned "spanning tree" with large complex diagram (Figure 1, 15 servers)
   - RFC 2810 (3): Provides concise definition: "The only network configuration allowed for IRC servers is that of a spanning tree where each server acts as a central node for the rest of the network it sees"
   - Simpler diagram (Figure 1: 5 servers, 4 clients) focuses on topology concepts
   - Explicit constraint: "The IRC protocol provides no mean for two clients to directly communicate. All communication between clients is relayed by the server(s)."

#### Key Content

**Section 1: Introduction (Lines 80-98)**

Critical acknowledgment of IRC's fundamental limitation:
> "This distributed model, which requires each server to have a copy of the global state information, is still the most flagrant problem of the protocol as it is a serious handicap, which limits the maximum size a network can reach."

This represents a significant shift from RFC 1459, which did not explicitly frame the distributed state model as a fundamental limitation in its introduction.

**Section 2: Components (Lines 100-145)**

**2.1 Servers:**
- "The only component of the protocol which is able to link all the other components together"
- Provides connection points for both clients [IRC-CLIENT] and servers [IRC-SERVER]
- Responsible for "providing the basic services defined by the IRC protocol"

**2.2 Clients:**
Definition: "A client is anything connecting to a server that is not another server"

**2.2.1 User Clients:**
- Programs with text-based interface for interactive communication
- "often referred as 'users'"

**2.2.2 Service Clients (NEW):**
This is RFC 2810's major architectural innovation compared to RFC 1459:
- Not intended for manual use or talking
- Limited chat function access
- Optional access to private server data
- "Typically automatons used to provide some kind of service"
- Example: Statistics collection about user origins

**Comparison with RFC 1459's Operators:**
- RFC 1459 (1.2.1): Operators were privileged human users with network maintenance powers (SQUIT, CONNECT, KILL)
- RFC 2810: Separates the concept - Service Clients are automated components, while operator privileges are now considered a user attribute rather than a component type

**Section 3: Architecture (Lines 147-177)**

**Network Definition:**
"An IRC network is defined by a group of servers connected to each other. A single server forms the simplest IRC network."

**Topology Constraint:**
"The only network configuration allowed for IRC servers is that of a spanning tree where each server acts as a central node for the rest of the network it sees."

**Diagram Evolution:**
- RFC 1459: Large, complex 15-server tree diagram emphasizing scale
- RFC 2810: Small 5-server, 4-client diagram emphasizing topology principles

**Critical Architectural Rule:**
"The IRC protocol provides no mean for two clients to directly communicate. All communication between clients is relayed by the server(s)."

This explicit statement formalizes what was implicit in RFC 1459's description.

**Section 4: IRC Protocol Services (Lines 179-211)**

RFC 2810 introduces an abstraction layer not present in RFC 1459: defining IRC as a set of "services" rather than just a message protocol. This services-oriented view separates what IRC does from how it does it.

**4.1 Client Locator:**
- Purpose: Enable clients to find each other
- Mechanism: Registration using labels upon connection
- Server responsibility: "keeping track of all the labels being used"
- RFC 1459 equivalent: Implicit in nickname registration discussion (1.2)

**4.2 Message Relaying:**
- Reiterates the client communication constraint
- Explicitly names "relaying" as a distinct service
- RFC 1459 equivalent: Described in server functionality (1.1) but not abstracted as a service

**4.3 Channel Hosting and Management:**
- Definition: "A channel is a named group of one or more users which will all receive messages addressed to that channel"
- Characterized by: name, members, properties
- Server responsibilities:
  - Host channels
  - Provide message multiplexing
  - Manage channels (track members)
- Reference to separate document [IRC-CHAN] for detailed channel management
- RFC 1459 equivalent: Section 1.3 Channels provided implementation details; RFC 2810 abstracts these into service concepts

**Key Differences from RFC 1459:**

1. **Abstraction Level**: RFC 2810 operates at architectural/service level vs. RFC 1459's mixed architecture/implementation approach

2. **Document Modularity**: RFC 2810 references separate documents for details ([IRC-CLIENT], [IRC-SERVER], [IRC-CHAN]) vs. RFC 1459's monolithic structure

3. **Service-Oriented Design**: RFC 2810 explicitly identifies three core protocol services, enabling clearer reasoning about what IRC provides

4. **Problem Acknowledgment**: RFC 2810 directly acknowledges the distributed state model as "the most flagrant problem of the protocol" in the introduction, whereas RFC 1459 only discussed scalability issues in Section 9 (Current Problems)

5. **Architectural Precision**: RFC 2810 provides precise definitions ("anything connecting to a server that is not another server") vs. RFC 1459's more descriptive approach

**Evolution Summary:**

RFC 2810 represents a maturation of IRC specification from a protocol description to an architectural framework. It:
- Separates concerns (architecture vs. implementation)
- Introduces service abstractions (Client Locator, Message Relaying, Channel Hosting)
- Formalizes component types (especially Service Clients)
- Acknowledges fundamental limitations upfront
- Provides clearer topology constraints
- Enables modular specification through document family structure

This architectural foundation allows RFC 2811-2813 to focus on specific aspects (channels, client protocol, server protocol) without repeating architectural concepts, improving specification clarity and maintainability.

---

### Section 5: IRC Concepts (moved from RFC 1459 Section 3)

#### Summary
RFC 1459 Section 3 "IRC Concepts" was migrated to become RFC 2810 Section 5 "IRC Concepts" as part of the protocol reorganization. This section describes the fundamental message delivery patterns in IRC: one-to-one, one-to-many, and one-to-all communications. While the core concepts remained intact during the migration, RFC 2810 introduced more formal language, reordered subsections for better clarity, and provided more precise technical specifications using RFC 2119 keywords (MUST, SHALL, REQUIRED).

#### Detailed Comparison

##### 5.1 One-To-One Communication

**RFC 1459 (Section 3.1):**
```
Communication on a one-to-one basis is usually only performed by
clients, since most server-server traffic is not a result of servers
talking only to each other.  To provide a secure means for clients to
talk to each other, it is required that all servers be able to send a
message in exactly one direction along the spanning tree in order to
reach any client.  The path of a message being delivered is the
shortest path between any two points on the spanning tree.
```

**RFC 2810 (Section 5.1):**
```
Communication on a one-to-one basis is usually performed by clients,
since most server-server traffic is not a result of servers talking
only to each other.  To provide a means for clients to talk to each
other, it is REQUIRED that all servers be able to send a message in
exactly one direction along the spanning tree in order to reach any
client.  Thus the path of a message being delivered is the shortest
path between any two points on the spanning tree.
```

**Key Changes:**
- **Language formalization:** "usually only performed" → "usually performed" (removed "only" for precision)
- **Security language removed:** "secure means" → "means" (reflects that security moved to architecture concerns)
- **RFC 2119 keywords:** "required" → "REQUIRED" (uppercase for formal requirement)
- **Clarity improvement:** Added "Thus" to make the logical connection explicit

**Examples:** Both versions use identical examples (1, 2, and 3) referencing Figure 2/1:
- Example 1: Message between clients 1 and 2 (same server)
- Example 2: Message between clients 1 and 3 (via servers A & B)
- Example 3: Message between clients 2 and 4 (via servers A, B, C & D)

**Analysis:** The concept is preserved exactly, but the language is more precise and formal in RFC 2810.

---

##### 5.2 One-To-Many

**Opening Paragraph Comparison:**

**RFC 1459 (Section 3.2):**
```
The main goal of IRC is to provide a  forum  which  allows  easy  and
efficient  conferencing (one to many conversations).  IRC offers
several means to achieve this, each serving its own purpose.
```

**RFC 2810 (Section 5.2):**
```
The main goal of IRC is to provide a forum which allows easy and
efficient conferencing (one to many conversations).  IRC offers
several means to achieve this, each serving its own purpose.
```

**Changes:**
- Minor formatting cleanup (removed extra spaces)
- Content identical

**MAJOR STRUCTURAL CHANGE:** The subsection order was completely reorganized:

**RFC 1459 Order:**
1. 3.2.1 To a list
2. 3.2.2 To a group (channel)
3. 3.2.3 To a host/server mask

**RFC 2810 Order:**
1. 5.2.1 To A Channel
2. 5.2.2 To A Host/Server Mask
3. 5.2.3 To A List

**Rationale for Reordering:**
The reordering places the most important and commonly used mechanism (channels) first, followed by the moderately used (host/server masks), and finally the least efficient method (lists). This better reflects actual IRC usage patterns and importance.

---

###### 5.2.1 To A Channel (was 3.2.2 To a group (channel))

**RFC 1459 (Section 3.2.2):**
```
In IRC the channel has a role equivalent to that of the multicast
group; their existence is dynamic (coming and going as people join
and leave channels) and the actual conversation carried out on a
channel is only sent to servers which are supporting users on a given
channel.  If there are multiple users on a server in the same
channel, the message text is sent only once to that server and then
sent to each client on the channel.  This action is then repeated for
each client-server combination until the original message has fanned
out and reached each member of the channel.
```

**RFC 2810 (Section 5.2.1):**
```
In IRC the channel has a role equivalent to that of the multicast
group; their existence is dynamic and the actual conversation carried
out on a channel MUST only be sent to servers which are supporting
users on a given channel.  Moreover, the message SHALL only be sent
once to every local link as each server is responsible to fan the
original message to ensure that it will reach all the recipients.
```

**Key Changes:**
1. **Removed explanatory parenthetical:** "(coming and going as people join and leave channels)" - considered self-evident
2. **Formalized requirements:** "is only sent" → "MUST only be sent" (RFC 2119 keyword)
3. **Added stricter requirement:** "SHALL only be sent once to every local link" (new formal constraint)
4. **Simplified explanation:** Removed detailed step-by-step fan-out description in favor of server responsibility statement
5. **More concise:** 107 words → 64 words while maintaining all essential information

**Technical Implication:** The RFC 2810 version is more prescriptive about server behavior (MUST, SHALL) while being less descriptive about mechanism.

**Examples:** Both versions use identical examples (4, 5, and 6):
- Example 4: 1 client in channel (nowhere to send)
- Example 5: 2 clients (like private message path)
- Example 6: Clients 1, 2, 3 (message fan-out demonstration)

---

###### 5.2.2 To A Host/Server Mask (was 3.2.3)

**RFC 1459 (Section 3.2.3):**
```
To provide IRC operators with some mechanism to send  messages  to  a
large body of related users, host and server mask messages are
provided.  These messages are sent to users whose host or server
information  match that  of  the mask.  The messages are only sent to
locations where users are, in a fashion similar to that of channels.
```

**RFC 2810 (Section 5.2.2):**
```
To provide with some mechanism to send messages to a large body of
related users, host and server mask messages are available.  These
messages are sent to users whose host or server information match
that of the mask.  The messages are only sent to locations where
users are, in a fashion similar to that of channels.
```

**Key Changes:**
1. **Scope broadened:** "IRC operators with some mechanism" → "with some mechanism" (removed "IRC operators" restriction)
2. **Wording update:** "are provided" → "are available" (more neutral language)
3. **Otherwise identical:** Core functionality description unchanged

**Analysis:** The removal of "IRC operators" suggests this mechanism may not be operator-only in all implementations, or RFC 2810 aimed to be less prescriptive about who can use this feature.

---

###### 5.2.3 To A List (was 3.2.1)

**RFC 1459 (Section 3.2.1):**
```
The least efficient style of one-to-many conversation is through
clients talking to a 'list' of users.  How this is done is almost
self explanatory: the client gives a list of destinations to which
the message is to be delivered and the server breaks it up and
dispatches a separate copy of the message to each given destination.
This isn't as efficient as using a group since the destination list
is broken up and the dispatch sent without checking to make sure
duplicates aren't sent down each path.
```

**RFC 2810 (Section 5.2.3):**
```
The least efficient style of one-to-many conversation is through
clients talking to a 'list' of targets (client, channel, mask).  How
this is done is almost self explanatory: the client gives a list of
destinations to which the message is to be delivered and the server
breaks it up and dispatches a separate copy of the message to each
given destination.

This is not as efficient as using a channel since the destination
list MAY be broken up and the dispatch sent without checking to make
sure duplicates aren't sent down each path.
```

**Key Changes:**
1. **Clarified target types:** "list of users" → "list of targets (client, channel, mask)" (explicit enumeration)
2. **Formalized uncertainty:** "is broken up" → "MAY be broken up" (RFC 2119 keyword acknowledging implementation variation)
3. **Terminology update:** "using a group" → "using a channel" (consistent with section 5.2.1 title change)
4. **Split into two paragraphs:** Better readability
5. **Improved grammar:** "This isn't" → "This is not" (more formal)

**Technical Implication:** The use of "MAY" in RFC 2810 acknowledges that implementation details vary, whereas RFC 1459 stated it as a certainty.

---

##### 5.3 One-To-All

**Opening Paragraphs Comparison:**

**RFC 1459 (Section 3.3):**
```
The one-to-all type of message is better described as a broadcast
message, sent to all clients or servers or both.  On a large network
of users and servers, a single message can result in a lot of traffic
being sent over the network in an effort to reach all of the desired
destinations.

For some messages, there is no option but to broadcast it to all
servers so that the state information held by each server is
reasonably consistent between servers.
```

**RFC 2810 (Section 5.3):**
```
The one-to-all type of message is better described as a broadcast
message, sent to all clients or servers or both.  On a large network
of users and servers, a single message can result in a lot of traffic
being sent over the network in an effort to reach all of the desired
destinations.

For some class of messages, there is no option but to broadcast it to
all servers so that the state information held by each server is
consistent between servers.
```

**Key Changes:**
1. **Precision improvement:** "For some messages" → "For some class of messages" (indicates categories, not individual messages)
2. **Strengthened requirement:** "reasonably consistent" → "consistent" (stronger consistency expectation)

**Analysis:** RFC 2810 removes the qualifier "reasonably" - reflecting that state consistency is critical, not optional.

---

###### 5.3.1 Client-to-Client

**RFC 1459 (Section 3.3.1):**
```
There is no class of message which, from a single message, results in
a message being sent to every other client.
```

**RFC 2810 (Section 5.3.1):**
```
There is no class of message which, from a single message, results in
a message being sent to every other client.
```

**Changes:** **IDENTICAL** - No changes whatsoever.

**Analysis:** This fundamental constraint of IRC (no client broadcast to all other clients) remained unchanged.

---

###### 5.3.2 Client-to-Server

**RFC 1459 (Section 3.3.2):**
```
Most of the commands which result in a change of state information
(such as channel membership, channel mode, user status, etc) must be
sent to all servers by default, and this distribution may not be
changed by the client.
```

**RFC 2810 (Section 5.3.2):**
```
Most of the commands which result in a change of state information
(such as channel membership, channel mode, user status, etc.) MUST be
sent to all servers by default, and this distribution SHALL NOT be
changed by the client.
```

**Key Changes:**
1. **Formalized requirement:** "must be sent" → "MUST be sent" (RFC 2119 keyword)
2. **Strengthened prohibition:** "may not be changed" → "SHALL NOT be changed" (RFC 2119 keyword)
3. **Punctuation fix:** "etc)" → "etc.)" (proper period before closing parenthesis)

**Analysis:** The use of RFC 2119 keywords (MUST, SHALL NOT) makes this a formal protocol requirement rather than a suggestion.

---

###### 5.3.3 Server-to-Server

**RFC 1459 (Section 3.3.3):**
```
While most messages between servers are distributed to all 'other'
servers, this is only required for any message that affects either a
user, channel or server.  Since these are the basic items found in
IRC, nearly all messages originating from a server are broadcast to
all other connected servers.
```

**RFC 2810 (Section 5.3.3):**
```
While most messages between servers are distributed to all 'other'
servers, this is only required for any message that affects a user,
channel or server.  Since these are the basic items found in IRC,
nearly all messages originating from a server are broadcast to all
other connected servers.
```

**Key Changes:**
1. **Grammar simplification:** "affects either a user" → "affects a user" (removed unnecessary "either")
2. **Otherwise identical:** Core requirement unchanged

**Analysis:** Minor grammar cleanup; the fundamental concept that state-affecting messages must be broadcast remains unchanged.

---

#### Changes and Clarifications

**1. Formalization Through RFC 2119 Keywords**

RFC 2810 systematically replaced informal requirement language with formal RFC 2119 keywords:
- "required" → "REQUIRED"
- "must" → "MUST"
- "may not" → "SHALL NOT"
- Added "MAY" where implementation flexibility exists

This transformation makes RFC 2810 a proper protocol specification suitable for interoperable implementations.

**2. Structural Reorganization**

The most significant change was reordering One-to-Many subsections from least-to-most important (RFC 1459) to most-to-least important (RFC 2810):

**Before (RFC 1459):**
- To a list (least efficient)
- To a group/channel (most important)
- To a host/server mask (moderate)

**After (RFC 2810):**
- To A Channel (most important)
- To A Host/Server Mask (moderate)
- To A List (least efficient)

This better reflects actual IRC usage and pedagogical clarity.

**3. Removed Implementation Details**

RFC 2810 removed specific implementation mechanism descriptions (e.g., detailed fan-out process for channels) in favor of responsibility statements. This gives implementers more flexibility while maintaining interoperability requirements.

**Example:**
- RFC 1459: "the message text is sent only once to that server and then sent to each client on the channel"
- RFC 2810: "each server is responsible to fan the original message to ensure that it will reach all the recipients"

**4. Strengthened Consistency Requirements**

RFC 2810 removed qualifiers like "reasonably" from consistency requirements:
- "reasonably consistent between servers" → "consistent between servers"

This reflects lessons learned about the importance of state synchronization in IRC networks.

**5. Broadened Scope Where Appropriate**

Some restrictions were loosened or made more general:
- Host/server mask messages: "IRC operators" restriction removed
- Implementations given flexibility: "is broken up" → "MAY be broken up"

**6. Terminology Standardization**

RFC 2810 updated terminology for consistency:
- "group" → "channel" (consistent naming)
- "users" → "targets (client, channel, mask)" (precise enumeration)
- "secure means" → "means" (security discussion moved to architecture)

**7. Precision Improvements**

Throughout the section, RFC 2810 made language more precise:
- "For some messages" → "For some class of messages"
- "affects either a user" → "affects a user"
- Removed redundant explanations that could be inferred

**8. What Was Preserved**

Despite all changes, the fundamental concepts were completely preserved:
- Spanning tree shortest-path routing for one-to-one
- Channel multicast semantics for one-to-many
- State synchronization broadcast for one-to-all
- No client-to-all-clients capability
- All examples remained identical

**9. Document Context**

The migration of this section from RFC 1459 to RFC 2810 (not RFC 2812) is significant:

- **RFC 1459:** Combined protocol specification (client + server + architecture)
- **RFC 2810:** Architecture document
- **RFC 2812:** Client protocol
- **RFC 2813:** Server protocol

The "IRC Concepts" section belongs in the Architecture document because it describes the fundamental communication patterns that underlie both client and server protocols. This organizational change reflects the maturation of IRC from a single specification to a properly layered protocol suite.

**10. Implications for Implementers**

The changes in RFC 2810 provide implementers with:
- **Clearer requirements:** RFC 2119 keywords remove ambiguity
- **Better organization:** Most important concepts first
- **Implementation flexibility:** MAY/SHOULD where appropriate, MUST where critical
- **Consistency expectations:** Stronger guarantees about state synchronization
- **Proper layering:** Architecture separate from protocol details

The migration successfully preserved all essential IRC concepts while modernizing the specification to meet IETF standards for protocol documentation.

---

## RFC 2813 Section 3: The IRC Server Specification

### Section 3: The IRC Server Specification

#### Summary

RFC 2813 Section 3 defines the IRC protocol specifically for server-to-server communications, representing a fundamental architectural split from RFC 1459. This section establishes strict security requirements for inter-server messaging, including mandatory prefix validation, automatic link termination for invalid sources, and prohibition of extended prefix formats. The specification emphasizes that server communication is primarily routing-oriented rather than reply-oriented, with most server messages not generating responses. It references the separate "IRC Client Protocol" (RFC 2812) document for detailed message format specifications and numeric reply lists.

#### Comparison with RFC 1459 Section 2

**Scope and Purpose:**
- **RFC 1459 Section 2**: Designed as a unified specification covering BOTH server-to-server AND client-to-server connections within a single protocol definition
- **RFC 2813 Section 3**: Explicitly scoped ONLY for server-to-server connections, with explicit referral to separate IRC Client Protocol for client connections

**Overview Philosophy (2.1 vs 3.1):**
- **RFC 1459**: "The protocol as described herein is for use both with server to server and client to server connections. There are, however, more restrictions on client connections (which are considered to be untrustworthy) than on server connections."
- **RFC 2813**: "The protocol as described herein is for use with server to server connections. For client to server connections, see the IRC Client Protocol specification."
- The shift represents a formal protocol separation, moving from a single document with different trust levels to separate specifications for different connection types

**Character Codes (2.2 vs 3.2):**
Both sections are nearly identical:
- 8-bit protocol based on octets
- Control codes used as message delimiters
- Delimiters and keywords allow USASCII terminal and telnet compatibility
- No specific character set required
- **Difference**: RFC 2813 inherits this unchanged, but the context is now purely server-to-server where character handling is more predictable (no untrusted client input)

**Message Handling Philosophy (2.3 vs 3.3):**

*RFC 1459 Section 2.3:*
```
"Servers and clients send eachother messages which may or may not
generate a reply. If the message contains a valid command, as
described in later sections, the client should expect a reply as
specified but it is not advised to wait forever for the reply; client
to server and server to server communication is essentially
asynchronous in nature."
```

*RFC 2813 Section 3.3:*
```
"Servers and clients send each other messages which may or may not
generate a reply. Most communication between servers do not generate
any reply, as servers mostly perform routing tasks for the clients."
```

**Key differences:**
- RFC 1459 focuses on asynchronous nature and client expectations
- RFC 2813 emphasizes the routing nature of server operations
- RFC 2813 explicitly states most server communication doesn't generate replies (routing-centric vs reply-centric model)

**Message Format Specifications:**

Both use identical basic structure:
- Optional prefix (indicated by leading ':')
- Command (letters or 3-digit numeric)
- Parameters (maximum 15)
- Components separated by ASCII space (0x20)

*RFC 1459 2.3 (spacing):*
```
"The prefix, command, and all parameters are separated by one (or more) 
ASCII space character(s) (0x20)."
```

*RFC 2813 3.3 (spacing):*
```
"The prefix, command, and all parameters are separated by one ASCII 
space character (0x20) each."
```

**Critical difference**: RFC 1459 allows "one (or more)" spaces as separators, while RFC 2813 specifies exactly "one ASCII space character (0x20) each" - a stricter requirement for server protocol.

**Prefix Validation and Security:**

*RFC 1459 Section 2.3 (lenient):*
```
"If the source identified by the prefix cannot be found from the 
server's internal database, or if the source is registered from a 
different link than from which the message arrived, the server must 
ignore the message silently."
```

*RFC 2813 Section 3.3 (strict):*
```
"When a server receives a message, it MUST identify its source using
the (eventually assumed) prefix. If the prefix cannot be found in
the server's internal database, it MUST be discarded, and if the
prefix indicates the message comes from an (unknown) server, the link
from which the message was received MUST be dropped."
```

**Major security enhancement:**
- RFC 1459: Silent message dropping only
- RFC 2813: Message discarding PLUS mandatory link termination for unknown server sources
- RFC 2813 adds: If prefix identifies client but message came from server link, issue KILL and propagate to all servers
- RFC 2813: Acknowledges "Dropping a link in such circumstances is a little excessive but necessary to maintain the integrity of the network and to prevent future problems"
- This represents a zero-tolerance approach to source spoofing in the server network

**Message Format BNF (2.3.1 vs 3.3.1):**

*RFC 1459 Section 2.3.1:* Titled "Message format in 'pseudo' BNF" and includes complete BNF specification:
```
<message>  ::= [':' <prefix> <SPACE> ] <command> <params> <crlf>
<prefix>   ::= <servername> | <nick> [ '!' <user> ] [ '@' <host> ]
<command>  ::= <letter> { <letter> } | <number> <number> <number>
<SPACE>    ::= ' ' { ' ' }
<params>   ::= <SPACE> [ ':' <trailing> | <middle> <params> ]
<middle>   ::= <Any *non-empty* sequence of octets not including SPACE
               or NUL or CR or LF, the first of which may not be ':'>
<trailing> ::= <Any, possibly *empty*, sequence of octets not including
                 NUL or CR or LF>
<crlf>     ::= CR LF
```

*RFC 2813 Section 3.3.1:* Titled "Message format in Augmented BNF" but does NOT include the BNF itself:
```
"The Augmented BNF representation for this is found in 'IRC Client
Protocol' [IRC-CLIENT]."
```

**Key change:**
- RFC 1459 embedded the complete BNF specification
- RFC 2813 references external document (RFC 2812) for BNF definition
- This creates dependency and ensures consistency between client and server protocols
- Title change from "pseudo BNF" to "Augmented BNF" suggests adoption of more formal RFC 2234 ABNF notation

**Critical Server-Specific Restriction:**

RFC 2813 Section 3.3.1 adds an explicit prohibition not present in RFC 1459:
```
"The extended prefix (["!" user "@" host ]) MUST NOT be used in server
to server communications and is only intended for server to client
messages in order to provide clients with more useful information
about who a message is from without the need for additional queries."
```

**Significance:**
- The extended prefix format `nick!user@host` is explicitly forbidden in server-to-server messages
- This format is reserved exclusively for server-to-client messages
- Prevents unnecessary bandwidth usage in server mesh
- Servers already maintain full user databases, making extended prefix redundant
- Clients benefit from extended prefix to avoid additional WHO/WHOIS queries

**Numeric Replies (2.4 vs 3.4):**

Both sections are nearly identical in text:

*RFC 1459 Section 2.4:*
```
"Most of the messages sent to the server generate a reply of some
sort. The most common reply is the numeric reply, used for both
errors and normal replies. The numeric reply must be sent as one
message consisting of the sender prefix, the three digit numeric, and
the target of the reply. A numeric reply is not allowed to originate
from a client; any such messages received by a server are silently
dropped. In all other respects, a numeric reply is just like a normal
message, except that the keyword is made up of 3 numeric digits
rather than a string of letters. A list of different replies is
supplied in section 6."
```

*RFC 2813 Section 3.4:*
```
"Most of the messages sent to the server generate a reply of some
sort. The most common reply is the numeric reply, used for both
errors and normal replies. The numeric reply MUST be sent as one
message consisting of the sender prefix, the three digit numeric, and
the target of the reply. A numeric reply is not allowed to originate
from a client; any such messages received by a server are silently
dropped. In all other respects, a numeric reply is just like a normal
message, except that the keyword is made up of 3 numeric digits
rather than a string of letters. A list of different replies is
supplied in 'IRC Client Protocol' [IRC-CLIENT]."
```

**Minor differences:**
- RFC 1459 uses "must" (lowercase)
- RFC 2813 uses "MUST" (RFC 2119 keyword - normative requirement)
- RFC 1459 references "section 6" (same document)
- RFC 2813 references "[IRC-CLIENT]" (RFC 2812 - separate document)

#### Server-Specific Extensions

**1. Strict Link Integrity Enforcement**

RFC 2813 introduces mandatory link termination rules not present in RFC 1459:

- **Unknown server source**: MUST drop link immediately
- **Prefix mismatch (source vs. arrival link)**: 
  - If message from server link but prefix identifies client: Issue KILL for client, propagate to all servers
  - For clients: SHOULD drop link
  - For servers: MUST drop link
- **Philosophy**: "Dropping a link in such circumstances is a little excessive but necessary to maintain the integrity of the network and to prevent future problems"

This represents evolution from RFC 1459's lenient "ignore the message silently" to aggressive network protection.

**2. Extended Prefix Prohibition**

Server-to-server protocol explicitly forbids the `nick!user@host` format:

```
The extended prefix (["!" user "@" host ]) MUST NOT be used in server
to server communications
```

**Rationale:**
- Servers maintain complete user databases, making extended info redundant
- Reduces bandwidth in server mesh
- Extended prefix reserved for server-to-client optimization (reduces WHO/WHOIS queries)
- Clear separation of concerns between server mesh and client access

**3. Stricter Spacing Requirements**

- RFC 1459: "one (or more) ASCII space character(s)" (tolerant parsing)
- RFC 2813: "one ASCII space character (0x20) each" (strict formatting)

This tightens the protocol for server-to-server, where both endpoints can be expected to format messages correctly.

**4. Routing-Centric Model**

RFC 2813 explicitly characterizes server behavior:

```
"Most communication between servers do not generate any reply, as 
servers mostly perform routing tasks for the clients."
```

This contrasts with RFC 1459's emphasis on asynchronous request-reply patterns. Server protocol prioritizes:
- Message forwarding and propagation
- State synchronization
- Minimal acknowledgment overhead
- Network topology maintenance

**5. Formal Protocol Separation**

RFC 2813 completes the architectural separation begun in RFC 1459:

- **RFC 1459**: Single protocol with trust level distinctions
- **RFC 2813 + RFC 2812**: Separate specifications for:
  - Server-to-Server (RFC 2813) - trusted, efficient, strict
  - Client-to-Server (RFC 2812) - untrusted, informative, lenient

**Cross-references:**
- BNF definition: Refers to [IRC-CLIENT] instead of embedding
- Numeric replies: Refers to [IRC-CLIENT] for authoritative list
- Client connections: Explicitly redirects to separate specification

**6. Normative Language Adoption**

RFC 2813 uses RFC 2119 keywords (MUST, SHOULD, MAY) consistently:

- "MUST be sent" (vs RFC 1459 "must be sent")
- "MUST be dropped" (new requirement)
- "MUST NOT be used" (new prohibition)
- "SHOULD be dropped" (conditional requirement)

This provides clearer implementation requirements and interoperability expectations.

#### How RFC 2813 Differs from RFC 2812's Client Specification

**Scope Division:**
- **RFC 2813 (Server Protocol)**: Server-to-server mesh communications, network integrity, message routing
- **RFC 2812 (Client Protocol)**: Client-to-server interactions, user commands, service access

**Trust Model:**
- **RFC 2813**: Trusted peer network with strict validation and harsh penalties for violations
- **RFC 2812**: Untrusted clients with lenient error handling and minimal disconnections

**Message Format:**
- **RFC 2813**: Prohibits extended prefix (`nick!user@host`), requires exact single-space separators
- **RFC 2812**: Allows extended prefix in server-to-client direction, more tolerant parsing

**Error Handling:**
- **RFC 2813**: Invalid sources trigger immediate link termination, KILL propagation
- **RFC 2812**: Invalid messages typically result in error replies to client

**Documentation Approach:**
- **RFC 2813**: References RFC 2812 for shared definitions (BNF, numeric codes)
- **RFC 2812**: Self-contained specification with complete message catalog

**Message Generation:**
- **RFC 2813**: Most messages don't generate replies (routing focus)
- **RFC 2812**: Most commands generate explicit replies (user interaction focus)

**Security Posture:**
- **RFC 2813**: Zero-tolerance for spoofing, network integrity paramount
- **RFC 2812**: User experience balanced with security, informative error messages

This architectural separation allows optimization of each protocol for its specific use case while maintaining a coherent overall IRC network architecture.

---
### Section 4.2: Channel Operations (Server Protocol)

#### Summary

RFC 2813 Section 4.2 describes server-to-server channel operations, introducing the NJOIN message as a major efficiency improvement for network synchronization. This section focuses on how servers propagate channel membership and state information across the IRC network, distinguishing server protocol from client protocol.

**Key documents:**
- RFC 2813 Section 4.2 (pages 14-16): Server Protocol - Channel Operations
- RFC 1459 Section 4.2 (pages 19-20): Client Protocol - JOIN message
- RFC 2812 Section 3.2 (pages 16-17): Client Protocol - Channel operations

#### NJOIN Message (NEW - RFC 2813 only)

**Command:** `NJOIN`  
**Parameters:** `<channel> [ "@@" / "@" ] [ "+" ] <nickname> *( "," [ "@@" / "@" ] [ "+" ] <nickname> )`

The NJOIN message is a server-only command introduced in RFC 2813 for efficient bulk channel membership synchronization during network joins (netjoins). This command does not exist in RFC 1459 or RFC 2812 (client protocols).

**Purpose and usage:**
- **Server-to-server only:** If received from a client, it MUST be ignored
- **Network synchronization:** Used when two servers connect to each other to exchange the complete list of channel members for each channel
- **Efficiency improvement:** While the same function can be performed using multiple successive JOIN messages, NJOIN SHOULD be used instead as it is significantly more efficient
- **Batch operation:** Allows transmitting multiple users' channel memberships in a single message

**User status encoding:**
- `@@` prefix: Indicates the user is the "channel creator"
- `@` prefix: Indicates a "channel operator"
- `+` prefix: Indicates the user has "voice" privilege
- No prefix: Regular channel member with no special privileges

**Example from RFC 2813:**
```
:ircd.stealth.net NJOIN #Twilight_zone :@WiZ,+syrk,avalon
```
This announces three users joining #Twilight_zone:
- WiZ with channel operator status (@)
- syrk with voice privilege (+)
- avalon with no special privileges

**Numeric replies:**
- ERR_NEEDMOREPARAMS
- ERR_NOSUCHCHANNEL
- ERR_ALREADYREGISTRED

**Comparison with client protocols:**
- **RFC 1459 and RFC 2812:** No equivalent command. Network synchronization must use individual JOIN messages
- **RFC 2813:** Introduces NJOIN specifically to reduce message overhead during netjoins and server linking

#### JOIN and MODE Differences

**4.2.1 JOIN Message - Server-to-Server Format**

**RFC 2813 (Server Protocol):**
```
Parameters: <channel>[ %x7 <modes> ] *( "," <channel>[ %x7 <modes> ] )
```

The server protocol extends JOIN with an optional channel modes parameter:
- User status (channel modes 'O', 'o', and 'v') may be appended to the channel name
- Separator: Control G (^G or ASCII 7, represented as %x7)
- **Server-only format:** This data MUST be ignored if the message wasn't received from a server
- **Client protection:** This format MUST NOT be sent to clients; it can only be used between servers
- **Deprecation note:** This format SHOULD be avoided (NJOIN is preferred)

**Broadcast requirement:**
> "The JOIN command MUST be broadcast to all servers so that each server knows where to find the users who are on the channel. This allows optimal delivery of PRIVMSG and NOTICE messages to the channel."

**RFC 1459 (Client Protocol):**
```
Parameters: <channel>{,<channel>} [<key>{,<key>}]
```

- Simpler format with optional channel keys
- No mode transmission capability
- Server-side validation: Only the local server validates whether a client is allowed to join
- Automatic propagation: All other servers automatically add the user when received from other servers

**RFC 2812 (Client Protocol):**
```
Parameters: ( <channel> *( "," <channel> ) [ <key> *( "," <key> ) ] ) / "0"
```

- Similar to RFC 1459 but with formal syntax notation
- Servers MUST be able to parse lists but SHOULD NOT use lists when sending JOIN to clients
- Adds "0" parameter for leaving all channels (not in RFC 1459's JOIN section)
- No server-to-server mode transmission mentioned (client protocol only)

**Key differences:**
1. **Mode transmission:** Only RFC 2813 supports transmitting user status (O/o/v) with JOIN
2. **Efficiency:** RFC 2813 deprecates the extended JOIN format in favor of NJOIN
3. **Client isolation:** RFC 2813 explicitly forbids sending server format to clients

**4.2.3 MODE Message - Server Handling**

All three RFCs describe MODE as a "dual-purpose command" affecting both channels and users, but they differ in emphasis and requirements.

**RFC 2813 (Server Protocol) - Section 4.2.3:**
- Brief treatment (8 lines total)
- **RECOMMENDED:** Parse entire message first, then pass on changes
- **REQUIRED:** Servers MUST be able to change channel modes to create "channel creator" and "channel operators"
- Server responsibility for establishing channel authority structure
- No detailed mode specifications (assumes knowledge from client protocol)

**RFC 1459 (Client Protocol) - Section 4.2.3:**
- Extended treatment with detailed mode specifications
- **Recommended:** Parse entire message first, then pass on changes (same guidance, weaker language)
- **Required:** Servers MUST be able to change channel modes for channel operator creation
- Detailed channel mode parameters:
  ```
  Parameters: <channel> {[+|-]|o|p|s|i|t|n|b|v} [<limit>] [<user>] [<ban mask>]
  ```
- Complete mode character definitions and behaviors
- Rationale: "one day nicknames will be obsolete and the equivalent property will be the channel"

**RFC 2812 (Client Protocol) - Section 3.2.3:**
- Most formal and detailed treatment
- Refers to separate "Internet Relay Chat: Channel Management" [IRC-CHAN] document for mode details
- **Maximum limit:** Three (3) changes per command for modes that take a parameter
- Enhanced numeric replies (11 different reply codes)
- More comprehensive error handling
- **Channel creator concept:** Formal error ERR_UNIQOPPRIVSNEEDED for MODE requiring "channel creator" privileges

**Key differences:**
1. **Detail level:** RFC 2813 provides minimal detail (server context only), RFC 1459 moderate detail, RFC 2812 most comprehensive with external references
2. **Requirements:** RFC 2813 emphasizes server capability requirements; RFC 1459 focuses on mode semantics; RFC 2812 adds rate limiting
3. **Channel creator:** RFC 2813 and RFC 2812 explicitly reference "channel creator" mode; RFC 1459 only mentions "channel operators"
4. **Parsing guidance:** RFC 2813 uses RECOMMENDED (RFC 2119), RFC 1459 uses informal "recommended"

#### How Servers Synchronize Channel State

**Network join scenario:**

1. **Server connection established:** Two servers complete SERVER/PASS handshake (Section 4.1.4)

2. **Channel membership exchange:**
   - **RFC 2813 preferred method:** Use NJOIN messages for each channel
     ```
     :server.example.net NJOIN #channel :@@creator,@op1,@op2,+voice1,user1,user2
     ```
   - **Alternative (should be avoided):** Individual JOIN messages with mode suffixes
     ```
     :user JOIN #channel^Go
     ```
     (where ^G is ASCII 7 and 'o' indicates operator status)

3. **Mode synchronization:**
   - Servers MUST be able to apply MODE changes to establish channel creator and operator status
   - MODE messages propagate through the network to maintain consistency
   - RFC 2813 emphasizes parsing the entire MODE message before applying changes

4. **Ongoing synchronization:**
   - All channel operations (JOIN, PART, MODE, KICK, QUIT) are broadcast to all servers
   - Each server maintains a map of which users are on which channels
   - This enables optimal routing of PRIVMSG and NOTICE to channels

**Race condition handling:**

RFC 2813 explicitly acknowledges race conditions:
> "In implementing these, a number of race conditions are inevitable when users at opposing ends of a network send commands which will ultimately clash."

Mitigation requirements:
- **Nickname history:** Servers REQUIRED to keep nickname history to ensure <nick> parameters are checked against recent changes
- **Message parsing:** RECOMMENDED to parse entire MODE message before applying (prevents partial state)
- **Automatic propagation:** Non-originating servers automatically accept channel membership changes from other servers (no validation)

**Comparison with client protocols:**

- **RFC 1459/2812:** Describe the theoretical requirement that "JOIN must be broadcast to all servers" but provide no implementation details
- **RFC 2813:** Provides concrete server-to-server mechanisms (NJOIN, mode suffixes) and acknowledges practical synchronization challenges
- **Efficiency evolution:** RFC 2813 shows awareness that the RFC 1459 approach (multiple JOINs) is inefficient at scale, introducing NJOIN as optimization

---

## RFC 2810 (Architecture) Sections 6-7: Current Problems & Security

### Summary

RFC 2810 (Internet Relay Chat: Architecture, April 2000) introduced a formalized "Current Problems" section that categorizes IRC's architectural challenges into four distinct areas: Scalability, Reliability, Network Congestion, and Privacy. This represents a significant shift from RFC 1459's approach, which embedded authentication details in Section 7 and discussed problems primarily from an implementation perspective in Section 9.

The security treatment also differs markedly: RFC 2810's Security Considerations section (Section 7) is remarkably brief, dismissing security as "irrelevant to this document" aside from privacy concerns. In contrast, RFC 1459 dedicated Section 7 to detailed authentication mechanisms and referenced security throughout multiple sections.

### New Problem Categories in RFC 2810

RFC 2810 Section 6 identifies four architectural problems, three of which represent new categorizations not explicitly separated in RFC 1459:

#### 6.1 Scalability
**RFC 2810 (Page 7):**
> It is widely recognized that this protocol does not scale sufficiently well when used in a large arena. The main problem comes from the requirement that all servers know about all other servers, clients and channels and that information regarding them be updated as soon as it changes.

**RFC 1459 Equivalent (Section 9.1, Page 63):**
> It is widely recognized that this protocol does not scale sufficiently well when used in a large arena. The main problem comes from the requirement that all servers know about all other servers and users and that information regarding them be updated as soon as it changes. It is also desirable to keep the number of servers low so that the path length between any two points is kept minimal and the spanning tree as strongly branched as possible.

**Analysis:** The scalability problem description is nearly identical between both RFCs. However, RFC 2810 adds "clients and channels" (versus RFC 1459's "servers and users"), reflecting more comprehensive state tracking. RFC 1459 included additional implementation guidance about keeping server counts low and maintaining minimal path lengths, which RFC 2810 omits.

#### 6.2 Reliability (NEW in RFC 2810)
**RFC 2810 (Page 7):**
> As the only network configuration allowed for IRC servers is that of a spanning tree, each link between two servers is an obvious and quite serious point of failure. This particular issue is addressed more in detail in "Internet Relay Chat: Server Protocol" [IRC-SERVER].

**RFC 1459:** No equivalent dedicated section. Reliability concerns were implicit but not explicitly categorized.

**Analysis:** RFC 2810 formally recognizes the spanning tree topology as a fundamental reliability problem. The single point of failure created by each server-to-server link is now explicitly documented as an architectural concern, with reference to RFC 2813 (Server Protocol) for details.

#### 6.3 Network Congestion (NEW in RFC 2810)
**RFC 2810 (Pages 7-8):**
> Another problem related to the scalability and reliability issues, as well as the spanning tree architecture, is that the protocol and architecture for IRC are extremely vulnerable to network congestions. This problem is endemic, and should be solved for the next generation: if congestion and high traffic volume cause a link between two servers to fail, not only this failure generates more network traffic, but the reconnection (eventually elsewhere) of two servers also generates more traffic.
> 
> In an attempt to minimize the impact of these problems, it is strongly RECOMMENDED that servers do not automatically try to reconnect too fast, in order to avoid aggravating the situation.

**RFC 1459:** Not explicitly discussed as a separate problem category. Message delivery issues were mentioned in Section 8.3 (implementation details) but not as an architectural problem.

**Analysis:** RFC 2810 identifies network congestion as a cascading problem where failures generate additional traffic, creating a positive feedback loop. The recommendation against rapid automatic reconnection is a new architectural guideline. This represents a mature understanding of IRC's operational challenges gained from 7 years of deployment experience between 1993 and 2000.

#### 6.4 Privacy (NEW in RFC 2810)
**RFC 2810 (Page 8):**
> Besides not scaling well, the fact that servers need to know all information about other entities, the issue of privacy is also a concern. This is in particular true for channels, as the related information is quite a lot more revealing than whether a user is online or not.

**RFC 1459 Equivalent (Section 9.2.2, Page 63):**
> The current channel layout requires that all servers know about all channels, their inhabitants and properties. Besides not scaling well, the issue of privacy is also a concern.

**Analysis:** Both RFCs mention privacy concerns related to global channel state knowledge. However, RFC 2810 elevates privacy to a standalone problem category (6.4) and explicitly notes that channel information is "a lot more revealing" than mere online presence. This reflects growing privacy awareness in the late 1990s.

### Security Considerations Comparison

The treatment of security differs dramatically between RFC 1459 and RFC 2810:

#### RFC 2810 Section 7: Security Considerations (Page 8)
**Complete text:**
> Asides from the privacy concerns mentioned in section 6.4 (Privacy), security is believed to be irrelevant to this document.

**Analysis:** This single-sentence dismissal is striking. RFC 2810 takes the position that security is outside the scope of an architecture document, aside from privacy. This likely reflects the decision to split security concerns between the client protocol (RFC 2812) and server protocol (RFC 2813) documents.

#### RFC 1459 Section 7: Client and server authentication (Pages 56-57)

RFC 1459 dedicated an entire section to authentication mechanisms:

**Authentication layers described:**
1. **IP to hostname lookup** - Reverse DNS verification for all connections
2. **Password checks** - Optional for clients, commonly used for servers
3. **Username identification** - IDENT protocol (RFC 1413) for username verification

**Key statement (Page 56):**
> Given that without passwords it is not easy to reliably determine who is on the other end of a network connection, use of passwords is strongly recommended on inter-server connections in addition to any other measures such as using an ident server.

**Analysis:** RFC 1459 treats authentication as a core protocol concern, providing specific implementation guidance. The progressive layering (DNS, password, IDENT) represents a defense-in-depth approach.

#### RFC 1459 Section 11: Security Considerations (Page 65)
**Complete text:**
> Security issues are discussed in sections 4.1, 4.1.1, 4.1.3, 5.5, and 7.

**Sections referenced:**
- **4.1, 4.1.1, 4.1.3** - Connection registration and password message details
- **5.5** - OPER message (operator authentication)
- **7** - Client and server authentication (detailed above)

**Analysis:** RFC 1459's security section acts as a cross-reference index, acknowledging that security is distributed throughout the protocol specification rather than isolated in a single section.

### Key Differences in Problem and Security Documentation

#### 1. Architectural vs. Implementation Focus

**RFC 2810:** Problems are framed as inherent architectural limitations:
- Spanning tree topology creates reliability issues
- Global state requirements create scalability issues
- Network congestion is a systemic architectural vulnerability

**RFC 1459:** Problems are framed as implementation challenges to be solved:
- Section 9 notes problems "hope to be solved sometime in the near future during its rewrite"
- Focuses on labels (9.2), algorithms (9.3), and implementation details
- More optimistic tone about future solutions

#### 2. Problem Categorization Evolution

**RFC 1459 Section 9 structure:**
- 9.1 Scalability
- 9.2 Labels (nicknames, channels, servers)
- 9.3 Algorithms (N^2 complexity, database consistency, race conditions)

**RFC 2810 Section 6 structure:**
- 6.1 Scalability (inherited from 1459)
- 6.2 Reliability (new category)
- 6.3 Network Congestion (new category)
- 6.4 Privacy (elevated from sub-issue to main category)

**What RFC 2810 removed:**
- **Labels problem (RFC 1459 9.2):** Nickname, channel, and server name collision issues
- **Algorithms problem (RFC 1459 9.3):** N^2 algorithms, lack of database consistency checks, race conditions from non-unique labels

**Analysis:** The removal of implementation-level problems (labels, algorithms) and addition of operational problems (reliability, congestion) reflects a shift from a protocol specification document to an architectural overview document. By 2000, the IRC community had accepted that certain problems (like label collisions and algorithmic complexity) were inherent rather than solvable.

#### 3. Security Documentation Philosophy

**RFC 1459 approach:**
- Security integrated throughout the document
- Dedicated section for authentication (Section 7)
- Practical implementation guidance (passwords, IDENT, DNS)
- Multiple cross-references in Security Considerations section

**RFC 2810 approach:**
- Security declared "irrelevant to this document"
- Only privacy concerns addressed
- Defers security to protocol-specific documents (RFC 2812/2813)
- Reflects modular document structure

**Analysis:** The difference reflects the document reorganization between 1993 and 2000. RFC 1459 was a monolithic specification covering all aspects; RFC 2810 is part of a suite where security details belong in protocol-specific documents. The dismissal of security as "irrelevant" is somewhat misleading—it's not that security doesn't matter, but rather that RFC 2810 is scoped as an architectural overview, not an implementation guide.

#### 4. Maturity and Acceptance of Limitations

**RFC 1459 (1993):**
- Acknowledges problems but expresses hope for solutions
- "all of which hope to be solved sometime in the near future during its rewrite"
- Active development mindset
- Problems framed as temporary

**RFC 2810 (2000):**
- Problems presented as inherent architectural characteristics
- Recommendations focus on mitigation (e.g., "do not automatically try to reconnect too fast")
- Acceptance that fundamental issues require "the next generation" of protocols
- Problems framed as endemic to the design

**Analysis:** Seven years of operational experience led to a more realistic assessment. By 2000, the IRC community understood that certain architectural decisions (spanning tree, global state) created fundamental limitations that could not be resolved without a complete redesign.

### Conclusion

The evolution from RFC 1459 Section 7 & 9 to RFC 2810 Section 6 & 7 reflects both document reorganization and community learning:

1. **Problems became categorized by impact area** (scalability, reliability, congestion, privacy) rather than implementation detail (labels, algorithms)

2. **New problem categories emerged** from operational experience: reliability of spanning tree topology and network congestion cascades were not initially recognized as distinct architectural issues

3. **Security treatment bifurcated**: RFC 1459 treated authentication as a core protocol concern; RFC 2810 deferred security to protocol-specific documents while elevating privacy to a first-class architectural concern

4. **Tone shifted from optimism to acceptance**: RFC 1459 hoped problems would be solved "in the near future"; RFC 2810 acknowledged they were "endemic" and would require "the next generation"

This evolution demonstrates how operational experience (1993-2000) led to a more nuanced understanding of IRC's fundamental architectural trade-offs and limitations.

---


## RFC 2813: Server Protocol Document

### Overview

RFC 2813 (April 2000) defines the server-to-server protocol for IRC, separating concerns that were previously combined in RFC 1459. While RFC 2812 focused on the client protocol, RFC 2813 addresses how servers communicate with each other to maintain network state and relay messages across the spanning tree topology.

**Key points from the Introduction (Section 1):**
- IRC servers connect to each other forming a network (client-server model extended to server-server)
- Originally a superset of the client protocol, but has evolved differently
- Development focused on scalability improvements
- Enabled world-wide networks to grow beyond old specification limits
- References separate architecture [IRC-ARCH] and channel management [IRC-CHAN] documents

**Scope:**
- Server-to-server communication protocol
- Three basic services: client locator (via client protocol), message relaying (via server protocol), channel hosting/management (via channel rules)
- Intended for implementers of IRC servers and services

### Section 2: Global Database

#### Comparison with RFC 1459/2812

**Architectural Framing:**
RFC 2813 explicitly introduces the concept of a "global state database" - a term not used in RFC 1459 or RFC 2812. This represents a fundamental shift in how the protocol conceptualizes network state:

- **RFC 1459 (Section 1)**: Describes servers, clients, and channels as independent components of the protocol without explicitly calling it a "database"
- **RFC 2812 (Section 1)**: Reorganizes the same information under "Labels" - treating them as identifiers rather than state
- **RFC 2813 (Section 2)**: Frames these components as a "global state database" that each server maintains about the entire network, emphasizing that this database is "in theory, identical on all servers"

This framing acknowledges the fundamental challenge of IRC: maintaining distributed consensus about global state across a spanning tree network.

**Evolution of Scope Concept:**

RFC 2813 introduces explicit acknowledgment that not all state is truly global:
- **Servers**: Generally known to all other servers (global), but hostmasking allows grouping and hiding individual servers
- **Clients**: Must be globally known (all servers track all clients)
- **Channels**: Have "scope" and are "not necessarily known to all servers" - acknowledging what RFC 1459 described as local (&) vs distributed (#) channels

This is a significant evolution from RFC 1459's simpler binary model (local vs distributed channels) to a more nuanced understanding of scope and visibility in the network.

**Relationship to Spanning Tree:**

While RFC 1459 Section 1.1 explicitly describes the spanning tree topology with an ASCII diagram, RFC 2813 assumes this knowledge and focuses instead on the state synchronization challenges this topology creates:
- The global database must be synchronized across all servers
- Server-to-server connections form the edges of the spanning tree
- State updates propagate through the tree structure
- The hostmask feature allows creating "areas" within the tree where internal structure is hidden from external servers

#### Key Content

**2.1 Servers**

**Identity and Naming:**
- Uniquely identified by name (maximum 63 characters)
- Name format defined by protocol grammar rules in Section 3.3.1

**Hostmasking (NEW feature not in RFC 1459/2812):**
- Servers can be grouped by defining a "hostmask"
- Within the hostmasked area: all servers have names matching the hostmask
- Outside the area: other servers see only a virtual server with the hostmask as its name
- Restriction: servers matching the hostmask SHALL NOT connect to the network outside the hostmasked area
- Effect: hides internal topology, improves scalability

**Comparison:**
- RFC 1459 (1.1): Described servers as "central nodes" in spanning tree, emphasized topology
- RFC 2812 (1.1): Simply defines server name length (63 chars), no topology discussion
- RFC 2813 (2.1): Adds hostmask concept for hierarchical topology hiding

**2.2 Clients**

**General Requirements:**
All servers MUST maintain for each client:
1. A netwide unique identifier (format depends on client type)
2. The server to which the client is connected

This is consistent across all RFCs but RFC 2813 makes it explicit as a database requirement.

**2.2.1 Users**

**Identity:**
- Distinguished by unique nickname (maximum 9 characters)
- Nickname format defined in Section 3.3.1 grammar rules

**Required Information:**
All servers MUST have for all users:
1. Nickname (unique identifier)
2. Hostname (the host the user is running on)
3. Username (on that host)
4. Server connection (which server the client is connected to)

**Comparison with RFC 1459:**
- RFC 1459 (1.2): "the real name of the host that the client is running on"
- RFC 2813 (2.2.1): "the name of the host that the user is running on"
- Subtle language shift from "real name" to "name" - acknowledging that DNS names may not always reflect "reality"

**Comparison with RFC 2812:**
- RFC 2812 (1.2.1): Only defines nickname length and format
- Does NOT specify what information servers must maintain about users
- This is appropriate since RFC 2812 is client protocol - server state requirements belong in server protocol

**2.2.2 Services**

**Identity:**
- Distinguished by service name = nickname + server name
- Nickname has maximum length of 9 characters
- Server name is the server to which the service is connected
- Format: Creates a compound identifier unique across the network

**Required Information:**
All servers MUST know:
1. Service name (nickname@servername format)
2. Service type

**Key Differences from Users:**
RFC 2813 explicitly documents how services differ from users:

1. **Identifier format**: Compound (nick + server) vs simple nickname
2. **Access rights**: Can request global state information vs normal client operations
3. **Command restrictions**: More restricted command set (see IRC-CLIENT for details)
4. **Channel access**: NOT allowed to join channels
5. **Flood control**: NOT subject to flood control mechanism (Section 5.8)

**Evolution:**
- RFC 1459: Does not have a "Services" concept in Section 1 (services were not formalized)
- RFC 2812 (1.2.2): Defines service identity but not the functional differences
- RFC 2813 (2.2.2): Fully documents services as a distinct client category with different privileges and restrictions

This formalization of services as first-class entities with special database access represents a major evolution in the protocol, enabling bots, authentication services, and other automated systems to integrate properly with the IRC network.

**2.3 Channels**

**Scope and Visibility:**
- Channels have "scope" (reference to [IRC-CHAN])
- Are NOT necessarily known to all servers
- When a channel's existence is known to a server, that server MUST track:
  1. Channel members (who is in the channel)
  2. Channel modes (channel state/configuration)

**Comparison with RFC 1459:**

RFC 1459 (1.3) described two channel types:
1. **Distributed channels** (starting with #): Known to all connected servers
2. **Local channels** (starting with &): Only exist on one server

RFC 1459 also described channel lifecycle:
- Created implicitly when first client joins
- Ceases to exist when last client leaves
- Can span network splits and rejoin when split heals

**Comparison with RFC 2812:**

RFC 2812 (1.3) describes channel identifiers:
- Strings beginning with &, #, +, or ! (four types vs two in RFC 1459)
- Maximum length 50 characters
- Explicitly states: "The definition of the channel types is not relevant to the client-server protocol"
- Defers channel semantics to [IRC-CHAN] document

**RFC 2813's Approach:**

RFC 2813 takes a middle ground:
- Acknowledges channels have "scope" (not all global)
- References [IRC-CHAN] for detailed channel type definitions
- Focuses on server state requirements: IF a server knows about a channel, it MUST track members and modes
- Does not specify channel lifecycle or creation semantics (those are in IRC-CHAN)

**Database Implications:**

The "scope" concept in RFC 2813 is crucial for scalability:
- Not all servers need to know about all channels
- Local/scoped channels reduce global state synchronization burden
- Servers only maintain channel state for channels they need to know about
- This allows the network to scale beyond a model where every server tracks every channel

This represents a significant architectural acknowledgment that true global state for channels is neither necessary nor desirable for scalability.

### Relationship to Spanning Tree Architecture

RFC 2813's Global Database concept is intrinsically tied to the spanning tree topology described in RFC 1459:

**State Synchronization:**
- Each server maintains its view of global state
- State updates propagate through the spanning tree structure
- Each server acts as a relay point for state updates to servers "behind" it in the tree
- The database should be "in theory, identical on all servers" - acknowledging that in practice, propagation delays and network splits create temporary inconsistencies

**Hierarchy and Abstraction:**
- Hostmasking creates hierarchical areas within the spanning tree
- External servers see aggregated/virtual servers rather than internal topology
- This allows scaling by reducing the O(N^2) full-mesh visibility problem

**Scope and Locality:**
- The spanning tree enables efficient scoped state (channels not known everywhere)
- State only propagates as far as needed based on channel scope
- Services can be server-local or network-wide depending on requirements

**Resilience:**
- Network splits partition the global database
- Each partition maintains its own consistent view
- When splits heal, state must be merged (channels, nicknames, modes)
- The spanning tree topology ensures there's always a unique path between any two servers, simplifying merge logic

### Key Insights

1. **Distributed Consensus Challenge**: RFC 2813 frames IRC's core challenge as maintaining a distributed database that should be identical across all servers - making explicit what was implicit in RFC 1459

2. **Scalability Through Scoping**: The evolution from RFC 1459 to RFC 2813 shows increasing sophistication about what needs to be global vs. what can be scoped (hostmasks for servers, scope for channels)

3. **Services as Database Consumers**: Formalizing services with special access to global state information represents recognition that network management and automation require programmatic access to the database

4. **Separation of Concerns**: By 2000, the protocol had evolved to separate:
   - Client protocol (RFC 2812): How clients interact, what identifiers mean
   - Server protocol (RFC 2813): How servers maintain and synchronize state
   - Channel management (IRC-CHAN): How channel semantics work
   - Architecture (IRC-ARCH): Overall system design

5. **Theoretical vs. Practical**: The phrase "in theory, identical on all servers" acknowledges that distributed systems face race conditions, propagation delays, and network partitions - the database is eventually consistent rather than strictly consistent

---
## RFC 2813 Section 5: Implementation Details

### Summary

RFC 2813 Section 5 "Implementation details" (pages 16-21) is the updated and reorganized version of RFC 1459 Section 8 "Current implementations" (pages 56-65). This section provides essential guidance for implementing IRC servers, covering connection management, state synchronization, nickname tracking, and performance optimizations. RFC 2813 introduces significant new features including compressed server links, anti-abuse protections, and formalized nickname delay mechanisms, while removing implementation-specific details like configuration file layouts.

### Key Comparisons with RFC 1459 Section 8

#### Connection Liveness (5.1 vs 8.4)

**RFC 2813 Changes:**
- Uses formal RFC 2119 language: "server MUST poll each of its connections"
- Explicitly references PING command from "IRC Client Protocol" [IRC-CLIENT]
- More concise presentation of the same concept

**RFC 1459 Original:**
- Informal language: "server must ping each of its connections"
- No formal protocol references
- Longer explanation of timeout behavior

**Unchanged:**
- Core mechanism: ping-based liveness detection
- Connection closure for non-responsive connections
- Sendq overflow handling (implicit in both)

**Analysis:** RFC 2813 formalizes the language without changing the fundamental mechanism. The explicit reference to the PING command location reflects the protocol split between client and server specifications.

---

#### Accepting Client-Server Connections (5.2 vs 8.5)

**Major RFC 2813 Changes:**

**NEW Structure - Separated subsections:**
- **5.2.1 Users**: Detailed user registration sequence
- **5.2.2 Services**: NEW - Separate handling for service connections

**5.2.1 Users - Enhanced Requirements:**
```
REQUIRED to send:
- RPL_WELCOME (user identifiers)
- RPL_YOURHOST (server name/version)
- RPL_CREATED (server birth info)
- RPL_MYINFO (available modes)
- MAY send introductory messages

SHALL send:
- LUSER reply (user/service/server count)
- MOTD (if any)

MUST use extended NICK message (Section 4.1.3)
- NOT separate NICK and USER messages as in IRC-CLIENT
```

**RFC 1459 Original (8.5):**
```
Required to send:
- MOTD (if present)
- LUSER command output
- Server name/version
- Introductory messages

Must send:
- NICK first, followed by USER
- Information from DNS/authentication servers
```

**5.2.2 Services (NEW in RFC 2813):**
```
Only sends:
- RPL_YOURESERVICE
- RPL_YOURHOST
- RPL_MYINFO

Uses SERVICE message to propagate to other servers
```

**Analysis:** RFC 2813 provides much more structured guidance with explicit reply codes and formal language. The separation of user and service registration is a significant organizational improvement. The mandate to use extended NICK messages (combining user info in one message) improves efficiency over the two-message approach in RFC 1459.

---

#### Server-Server Connection Establishment (5.3 vs 8.6)

**RFC 2813 Major Additions:**

**5.3.1 Link Options (COMPLETELY NEW)**

RFC 2813 introduces a formalized link options system using the PASS message options parameter:

**5.3.1.1 Compressed Server Links (NEW):**
```
Z flag in PASS options parameter:
- Both servers must request compression
- Both must successfully initialize compressed streams
- Uses RFC 1950 (ZLIB), RFC 1951 (DEFLATE), RFC 1952 (GZIP)
- Failure: send uncompressed ERROR and close connection

Benefits:
- Reduced bandwidth usage on server links
- Particularly valuable for networks with slow connections
- Standardized compression format
```

**5.3.1.2 Anti-Abuse Protections (NEW):**
```
P flag in PASS options parameter:
- Requires all servers on network implement abuse protections
- If present, server REQUIRES all its server links enable protections
- Commonly referenced protections:
  - Section 5.7: Tracking recently used nicknames
  - Section 5.8: Flood control of clients

Purpose:
- Network-wide enforcement of abuse prevention
- Ensures consistent protection across server links
- Indispensable on some networks, superfluous on others
```

**RFC 1459 Original (8.6):**
```
Basic PASS/SERVER exchange:
- Receive PASS/SERVER pair
- Validate as being valid
- Reply with own PASS/SERVER
- Send all state information
- Initiating server checks authentication
```

**Unchanged Core Process:**
- PASS/SERVER pair exchange and validation
- Mutual authentication required
- State information exchange after authentication
- Race condition awareness

**Analysis:** The link options system is one of RFC 2813's most significant additions. Compressed links address bandwidth concerns that became more apparent as IRC networks grew. The anti-abuse flag system allows networks to enforce consistent security policies across all server links, preventing weak links in the security chain.

---

#### State Information Exchange (5.3.2 vs 8.6.1)

**RFC 2813 Changes:**

```
REQUIRED order:
1. All known servers (SERVER messages)
2. All known client information (NICK and SERVICE messages)
3. All known channel information (NJOIN/MODE messages)

Channel topics: SHOULD NOT be exchanged
Reasoning: TOPIC overwrites old topic, sides would just exchange topics
```

**RFC 1459 Original:**

```
Required order:
1. All known other servers (SERVER messages)
2. All known user information (NICK/USER/MODE/JOIN messages)
3. All known channel information (MODE messages)

Channel topics: NOT exchanged
Reasoning: TOPIC overwrites, so at best sides exchange topics
```

**Key Differences:**

| Aspect | RFC 2813 | RFC 1459 |
|--------|----------|----------|
| Terminology | "Client information" | "User information" |
| User sync | NICK and SERVICE messages | NICK/USER/MODE/JOIN |
| Channel sync | NJOIN/MODE messages | MODE messages |
| Services | Explicitly included (SERVICE) | Not mentioned |
| Topic exchange | "SHOULD NOT" (formal) | "NOT" (informal) |

**Unchanged Philosophy:**
- Servers first to detect server collisions before nickname collisions
- Collision location indicates network split point
- Acyclic graph topology requirement
- Network may have reconnected elsewhere

**Analysis:** RFC 2813's use of "client information" reflects the broader concept including both users and services. The NJOIN command (efficient bulk channel membership synchronization) replaces individual JOIN messages. The explicit inclusion of SERVICE messages formalizes service support. The change from "NOT" to "SHOULD NOT" uses RFC 2119 language properly.

---

#### Terminating Connections

**Server-Client Termination (5.4 vs 8.7):**

**RFC 2813 (5.4):**
```
When client connection unexpectedly closes:
- QUIT message generated on behalf of client
- By the server to which client was connected
- No other message to be generated or used
```

**RFC 1459 (8.8):**
```
When client connection closes:
- QUIT message generated on behalf of client
- No other message to be generated or used
```

**Difference:** RFC 2813 adds "unexpectedly" qualifier and clarifies which server generates the message.

---

**Server-Server Termination (5.5 vs 8.8):**

**RFC 2813 (5.5):**
```
If server-server connection closed (SQUIT or natural causes):
- Rest of IRC network MUST have information updated
- Server which detected closure sends:
  - List of SQUITs (one for each server behind connection)
- Reference to Section 4.1.6 (SQUIT)
```

**RFC 1459 (8.8):**
```
If server-server connection closed (SQUIT or natural causes):
- Rest of connected IRC network must have information updated
- Server which detected closure sends:
  - List of SQUITs (one for each server behind connection)
  - List of QUITs (one for each client behind connection)
```

**Significant Difference:** RFC 2813 **removes the explicit requirement to send QUIT messages** for clients behind the connection. This is a protocol simplification - the SQUIT implicitly invalidates all clients behind that server.

**Analysis:** The removal of explicit QUIT requirements suggests this was handled implicitly by server implementations. When a server receives SQUIT for a remote server, it already knows to invalidate all associated clients. The explicit QUIT messages may have been redundant network traffic.

---

#### Nickname Tracking (5.6 vs 8.9)

**RFC 2813 (5.6):**
```
Servers REQUIRED to keep history of recent nickname changes
Purpose: Mitigate race conditions

Commands that MUST trace nick changes:
- KILL (nick being disconnected)
- MODE (+/- o,v on channels)
- KICK (nick being removed from channel)

No other commands need to check nick changes.

Process:
1. Check for nickname existence
2. Check history to see who nick now belongs to
3. RECOMMENDED: use time range, ignore old entries

History size: SHOULD keep previous nickname for every client
Limited by: memory and other factors
```

**RFC 1459 (8.9):**
```
All IRC servers required to keep history of recent nickname changes
Purpose: Keep in touch when nick-change race conditions occur

Commands which must trace nick changes:
- KILL (nick being killed)
- MODE (+/- o,v)
- KICK (nick being kicked)

No other commands to have nick changes checked.

Process:
1. Check for nickname existence
2. Check history to see who nick currently belongs to (if anyone!)
3. Recommended: time range be given, ignore too-old entries

History size: should keep previous nickname for every client
Limited by: memory, etc
```

**Key Differences:**

| Aspect | RFC 2813 | RFC 1459 |
|--------|----------|----------|
| Language | REQUIRED, MUST, RECOMMENDED | required, must, recommended |
| KILL description | "nick being disconnected" | "nick being killed" |
| MODE description | "+/- o,v on channels" | "+/- o,v" |
| History check | "nick now belongs to" | "nick currently belongs to" |

**Analysis:** Nearly identical functionality with formalized language in RFC 2813. The change from "killed" to "disconnected" is more neutral terminology. The MODE clarification explicitly mentions "on channels" which was implicit in RFC 1459.

---

#### Tracking Recently Used Nicknames (5.7 - NEW in RFC 2813)

**COMPLETELY NEW Section:**

This section, commonly known as "Nickname Delay," is entirely new to RFC 2813:

```
Purpose:
- Significantly reduce nickname collisions from network splits/reconnections
- Reduce abuse potential
- Proven effective mechanism

Mechanism:
Servers SHOULD keep track of nicknames that were:
- Recently used AND
- Released due to network split OR KILL message

These nicknames become:
- Unavailable to server local clients
- Cannot be re-used even though not currently in use
- Blocked for a certain period of time

Duration considerations:
- Network size (user wise)
- Usual duration of network splits
- SHOULD be uniform on all servers for given IRC network

Reference from 5.3.1.2:
- Part of "commonly found protections"
- Can be enforced network-wide via P flag
```

**Why This Is New:**

RFC 1459 had no equivalent section. While RFC 1459 tracked nickname *changes* (Section 8.9), it did not track recently *released* nicknames.

**Problem Addressed:**

Classic scenario:
1. Network splits into two parts
2. User A on one side, User B on other side
3. User A disconnects, releasing nickname "Alice"
4. User B immediately claims "Alice" on their side
5. Network reconnects
6. Collision: both sides have different "Alice"
7. One or both get killed

**Nickname Delay Solution:**

1. Network splits
2. User A disconnects, server marks "Alice" as delayed
3. User B tries to claim "Alice" - DENIED (nickname delay active)
4. Network reconnects
5. No collision because "Alice" was protected

**Analysis:** This is a major anti-abuse and stability improvement. The explicit formalization in RFC 2813 suggests it became a standard practice after RFC 1459. The requirement for uniform duration across networks shows awareness of the need for consistent behavior. The reference from the anti-abuse protections section (5.3.1.2) shows this became a key network protection mechanism.

---

#### Flood Control (5.8 vs 8.10)

**RFC 2813 (5.8):**
```
Purpose: Protect network from client message flooding

Applied to: All clients except services
Exception: Services MAY also be subject to this mechanism

Algorithm:
1. Check if client's message timer < current time (set equal if true)
2. Read any data present from client
3. While timer < 10 seconds ahead of current time:
   - Parse present messages
   - Penalize client by 2 seconds for each message
4. Additional penalties MAY be used for specific commands
   which generate lot of traffic across network

Result: Client may send 1 message every 2 seconds without being adversely affected
```

**RFC 1459 (8.10):**
```
Purpose: Provide flood protection at server (not client responsibility)

Applied to: All clients except services

Algorithm:
1. Check if client's message timer < current time (set equal if true)
2. Read any data present from client  
3. While timer < 10 seconds ahead of current time:
   - Parse present messages
   - Penalize client by 2 seconds for each message

Result: Client may send 1 message every 2 seconds without being adversely affected

Services: Explicitly exempted from flood control
```

**Key Differences:**

| Aspect | RFC 2813 | RFC 1459 |
|--------|----------|----------|
| Services exemption | "MAY also be subject" | "except services" (firm exemption) |
| Additional penalties | NEW: "MAY be used for specific commands" | Not mentioned |
| Formatting | Bullet points | Indented list with semicolons |

**Additional Penalties (NEW):**

RFC 2813 introduces the concept of command-specific penalties:
- Some commands generate more network traffic
- Examples might include: WHOIS, WHO, LIST
- Servers MAY impose higher penalties for expensive commands
- Prevents abuse through resource-intensive queries

**Services Change:**

RFC 1459: Services completely exempt (never subject to flood control)
RFC 2813: Services MAY be subject to flood control (server's choice)

**Rationale:** Malicious or buggy services could still flood the network. Allowing servers to apply flood control to services provides additional protection while maintaining flexibility.

**Analysis:** The basic algorithm remains identical (1 message per 2 seconds), but RFC 2813 adds important flexibility. The command-specific penalties acknowledge that not all messages have equal cost. The services change reflects maturity in understanding that services, while typically trusted, may still need rate limiting.

---

#### Non-blocking Lookups (5.9 vs 8.11)

**RFC 2813 (5.9):**
```
Requirement: Real-time environment with minimal waiting
- Essential for fair service to all clients
- Requires non-blocking I/O on all network read/write operations
- Support operations may cause blocking (e.g., disk reads)
- Such activity SHOULD be performed with short timeout

5.9.1 Hostname (DNS) lookups:
- Standard resolver libraries cause large delays on timeouts
- Solution: Separate set of DNS routines written for current implementation
- Setup for non-blocking I/O operations with local cache
- Polled from within main server I/O loop

5.9.2 Username (Ident) lookups:
- Numerous ident libraries exist implementing "Identification Protocol" [IDENT]
- Problem: Operated in synchronous manner, resulted in frequent delays
- Solution: Set of routines cooperating with rest of server
- Work using non-blocking I/O
```

**RFC 1459 (8.11):**
```
Requirement: Real-time environment, server does minimal waiting
- Essential so all clients are serviced fairly
- Requires non-blocking I/O on all network read/write operations
- Support operations may cause server to block (e.g., disk reads)
- Such activity should be performed with short timeout

8.11.1 Hostname (DNS) lookups:
- Berkeley and other standard resolver libraries meant large delays
- Delays occurred where replies timed out
- Solution: Separate set of DNS routines written
- Setup for non-blocking I/O operations
- Polled from within main server I/O loop

8.11.2 Username (Ident) lookups:
- Numerous ident libraries for use and inclusion into programs
- Problem: Operated in synchronous manner, resulted in frequent delays
- Solution: Set of routines cooperating with rest of server
- Work using non-blocking I/O
```

**Key Differences:**

| Aspect | RFC 2813 | RFC 1459 |
|--------|----------|----------|
| Language | "SHOULD be performed" (formal) | "should be performed" (informal) |
| DNS cache | "with local cache" (explicit) | Not mentioned |
| Ident reference | References [IDENT] protocol formally | No formal reference |
| Implementation note | "for the current implementation" | Implied as general practice |

**New in RFC 2813:**
- **Local cache** for DNS explicitly mentioned
- **Formal reference** to Identification Protocol [IDENT]
- **Qualification** that DNS routines were "for the current implementation" (acknowledges other implementations may differ)

**Analysis:** The content is nearly identical, showing these techniques remained best practice. The explicit mention of DNS caching in RFC 2813 highlights an important optimization. The formal IDENT reference reflects better documentation standards. The "current implementation" qualifier shows awareness that RFC 2813 describes one approach, not mandating specific implementation.

---

### Sections Removed from RFC 2813

RFC 1459 Section 8 included several subsections that were **completely removed** from RFC 2813:

#### 8.1 Network protocol: TCP (REMOVED)

**RFC 1459 content:**
- Rationale for using TCP as reliable network protocol
- Discussion of multicast IP as alternative (not widely available)

**8.1.1 Support of Unix sockets (REMOVED)**
- Configuration to accept connections on Unix domain sockets
- Recognition of paths starting with '/'
- Hostname substitution requirements

**Reason for removal:** These are implementation choices, not protocol requirements. The choice of TCP became obvious and didn't need justification in a 2000 standard.

---

#### 8.2 Command Parsing (REMOVED)

**RFC 1459 content:**
- Private input buffer design (512 bytes per connection)
- Non-buffered network I/O implementation
- Parsing after every read operation
- Handling multiple messages with care for client removal

**Reason for removal:** Implementation detail, not protocol specification. Different implementations may use different buffering strategies.

---

#### 8.3 Message delivery (REMOVED)

**RFC 1459 content:**
- "Send queue" as FIFO queue for outgoing data
- Queue management for saturated network links
- Typical queue sizes (up to 200 Kbytes)
- Polling strategy: read/parse all input first, then send queued data
- Reduction of write() system calls and TCP packet optimization

**Reason for removal:** Implementation optimization, not protocol requirement. Modern servers may use different queuing strategies.

---

#### 8.12 Configuration File (REMOVED - Entire Section)

**RFC 1459 content included:**

**8.12 Configuration File:**
- Flexible server setup via configuration file
- Which hosts to accept client connections from
- Which hosts to allow as servers
- Which hosts to connect to (active/passive)
- Server location information
- Administrator contact information
- Operator hostnames and passwords

**8.12.1 Allowing clients to connect:**
- Access control list (ACL) read at startup
- Both 'deny' and 'allow' implementations

**8.12.2 Operators:**
- Two-password requirement
- Storage in configuration files
- Crypted password format using crypt(3)
- Protection against abuse and theft

**8.12.3 Allowing servers to connect:**
- Server connection whitelist (bidirectional)
- No arbitrary host connections
- Password and link characteristics storage

**8.12.4 Administrivia:**
- Administrator details for ADMIN command
- Server location information
- Responsible party contact
- Hostname formats (domain names and dot notation)

**Reason for removal:** These are entirely implementation details. Different IRC server software (ircd, ircd-hybrid, UnrealIRCd, etc.) use vastly different configuration formats. Specifying configuration file structure in a protocol document is inappropriate.

---

#### 8.13 Channel membership (REMOVED)

**RFC 1459 content:**
- Limit: 10 channels per local user
- No limit for non-local users (consistency across network)

**Reason for removal:** Implementation policy, not protocol requirement. Different networks and servers have different limits.

---

### New in RFC 2813

Features that appear in RFC 2813 Section 5 but not in RFC 1459 Section 8:

1. **Compressed Server Links (5.3.1.1)**
   - Z flag in PASS options
   - zlib/deflate/gzip compression
   - Bandwidth optimization for server links

2. **Anti-Abuse Protections Flag (5.3.1.2)**
   - P flag in PASS options
   - Network-wide enforcement of abuse protections
   - References to nickname delay and flood control

3. **Service Registration (5.2.2)**
   - Separate subsection for service connections
   - Different reply sequence (RPL_YOURESERVICE, RPL_YOURHOST, RPL_MYINFO)
   - SERVICE message propagation

4. **Tracking Recently Used Nicknames (5.7)**
   - Nickname delay mechanism
   - Post-split and post-KILL nickname blocking
   - Duration considerations for network size
   - Uniform duration requirements

5. **Extended NICK Message Requirement (5.2.1)**
   - Must use extended NICK format for server-to-server
   - Replaces separate NICK and USER messages
   - More efficient state synchronization

6. **NJOIN for Channel Synchronization (5.3.2)**
   - Bulk channel membership exchange
   - Replaces individual JOIN messages
   - More efficient state transfer

7. **Command-Specific Flood Penalties (5.8)**
   - Additional penalties for high-traffic commands
   - Flexibility beyond basic 2-second-per-message rule

8. **Services Flood Control Option (5.8)**
   - Services MAY be subject to flood control
   - Changed from firm exemption in RFC 1459

9. **DNS Local Cache Mention (5.9.1)**
   - Explicit mention of caching in DNS lookups
   - Performance optimization documentation

10. **Formal Protocol References**
    - [IRC-CLIENT] references for PING, NICK, etc.
    - [IDENT] reference for Identification Protocol
    - [ZLIB], [DEFLATE], [GZIP] for compression
    - Better standards documentation

---

### Language and Formalization Changes

**RFC 2119 Keywords:**

RFC 2813 consistently uses formal requirement levels:
- **MUST / MUST NOT**: Absolute requirements
- **REQUIRED / SHALL**: Absolute requirements (synonyms)
- **SHOULD / SHOULD NOT**: Strong recommendations
- **RECOMMENDED**: Strong recommendations
- **MAY**: Optional features

RFC 1459 used informal language:
- "must", "should", "required" without RFC 2119 semantics
- Less clear distinction between requirements and recommendations

**Examples:**

| Topic | RFC 1459 | RFC 2813 |
|-------|----------|----------|
| Polling connections | "must ping" | "MUST poll" |
| User registration | "required to send" | "REQUIRED to send" |
| State exchange order | "required order" | "REQUIRED order" |
| Topic exchange | "NOT exchanged" | "SHOULD NOT be exchanged" |
| Nickname history | "required to keep" | "REQUIRED to keep" |
| History size | "should be able to keep" | "SHOULD be able to keep" |

**Impact:** RFC 2813's formal language makes implementation requirements unambiguous and testable.

---

### Structural Improvements

**RFC 2813 Organization:**
```
5. Implementation details
   5.1 Connection 'Liveness'
   5.2 Accepting a client to server connection
       5.2.1 Users
       5.2.2 Services
   5.3 Establishing a server-server connection
       5.3.1 Link options
           5.3.1.1 Compressed server to server links
           5.3.1.2 Anti abuse protections
       5.3.2 State information exchange when connecting
   5.4 Terminating server-client connections
   5.5 Terminating server-server connections
   5.6 Tracking nickname changes
   5.7 Tracking recently used nicknames
   5.8 Flood control of clients
   5.9 Non-blocking lookups
       5.9.1 Hostname (DNS) lookups
       5.9.2 Username (Ident) lookups
```

**RFC 1459 Organization:**
```
8. Current implementations
   8.1 Network protocol: TCP
       8.1.1 Support of Unix sockets
   8.2 Command Parsing
   8.3 Message delivery
   8.4 Connection 'Liveness'
   8.5 Establishing a server to client connection
   8.6 Establishing a server-server connection
       8.6.1 Server exchange of state information when connecting
   8.7 Terminating server-client connections
   8.8 Terminating server-server connections
   8.9 Tracking nickname changes
   8.10 Flood control of clients
   8.11 Non-blocking lookups
       8.11.1 Hostname (DNS) lookups
       8.11.2 Username (Ident) lookups
   8.12 Configuration File
       8.12.1 Allowing clients to connect
       8.12.2 Operators
       8.12.3 Allowing servers to connect
       8.12.4 Administrivia
   8.13 Channel membership
```

**Key Organizational Changes:**

1. **Removed implementation-specific sections** (8.1, 8.2, 8.3, 8.12, 8.13)
2. **Added hierarchical link options** (5.3.1.x - new feature organization)
3. **Split client acceptance** into users and services (5.2.1, 5.2.2)
4. **Added nickname delay** as separate section (5.7)
5. **Streamlined structure** focusing on protocol requirements, not implementation choices

**Result:** RFC 2813 is more focused on **what must be implemented** (protocol behavior) versus **how to implement it** (implementation techniques).

---

### Overall Assessment

**Philosophy Shift:**

RFC 1459 Section 8 mixed:
- Protocol requirements (connection liveness, state sync)
- Implementation guidance (buffering, queuing)
- Configuration advice (config files, operator passwords)
- Performance optimizations (non-blocking I/O)

RFC 2813 Section 5 focuses on:
- Protocol requirements exclusively
- Interoperability needs
- Network-wide features (compression, anti-abuse)
- State management requirements

**Maturity Indicators:**

1. **Formalized language** - RFC 2119 compliance
2. **New features** - Compression and anti-abuse show protocol evolution
3. **Services integration** - Explicit service support throughout
4. **Network protection** - Nickname delay and enhanced flood control
5. **Better references** - Formal citations to related RFCs
6. **Removed bloat** - Configuration details moved to implementation docs

**Backward Compatibility:**

Core mechanisms unchanged:
- Connection liveness (PING-based)
- State synchronization order
- Nickname change tracking
- Basic flood control algorithm
- Non-blocking lookup approach

New features are optional:
- Compression (Z flag) - negotiated
- Anti-abuse (P flag) - network policy choice
- Nickname delay - SHOULD, not MUST
- Command penalties - MAY add extras

**Conclusion:**

RFC 2813 Section 5 represents a **refinement and formalization** of RFC 1459 Section 8. It removes implementation advice that doesn't belong in a protocol specification while adding important new features that address real operational needs (bandwidth optimization via compression, abuse prevention via nickname delay and enforced protections). The consistent use of RFC 2119 language makes requirements testable and unambiguous. The protocol evolution shows learning from nearly a decade of IRC operational experience between 1993 (RFC 1459) and 2000 (RFC 2813).

---

## RFC 2813 Section 4.1: Connection Registration (Server Protocol)

### Summary

This section compares server-to-server connection registration between RFC 1459 Section 4.1 and RFC 2813 Section 4.1, focusing on the commands specific to server protocol that were removed from RFC 2812 (the client protocol).

**RFC 1459 Section 4.1** combined both client and server connection registration in a single section, documenting how both types of connections establish themselves on the IRC network.

**RFC 2813 Section 4.1** focuses exclusively on server-to-server connection registration, extracting and expanding the server-specific portions from RFC 1459.

**Key distinction:**
- **Client registration**: PASS (optional) → NICK → USER
- **Server registration**: PASS (required) → SERVER

The server protocol uses enhanced versions of NICK and SERVICE to propagate new users and services across the server mesh, rather than the separate NICK/USER messages used by clients.

---

### PASS Message (Server Password Handling)

**RFC 1459 Section 4.1.1:**
```
Command: PASS
Parameters: <password>
```
- Single password parameter
- MUST be sent before SERVER command (for servers)
- Only last PASS before registration is used
- Simple password verification
- Multiple PASS commands allowed before registration, but only last one counts

**RFC 2813 Section 4.1.1:**
```
Command: PASS
Parameters: <password> <version> <flags> [<options>]
```

**Major enhancements:**

1. **`<version>`** parameter (NEW):
   - Format: 4 digits + 6 digits (e.g., "0210010000")
   - First 4 digits: Protocol version (0210 = version 2.10)
   - Last 6 digits: Implementation-specific flags
   - Enables version negotiation between servers

2. **`<flags>`** parameter (NEW):
   - Capability flags indicating server features
   - Format: alphanumeric string with special characters
   - Example: "IRC|aBgH$" indicates various capabilities
   - Enables feature negotiation during connection

3. **`<options>`** parameter (NEW, optional):
   - Extended server capabilities
   - Format varies by implementation
   - Examples: "Z" for compression, "P" for anti-abuse protections
   - Future extensibility for new features

**Stricter requirements:**
- PASS MUST be sent before SERVER (not optional for servers)
- Only ONE (1) PASS command SHALL be accepted
- Last three (3) parameters MUST be ignored if received from client
- Better version compatibility checking

**Example:**
```
PASS moresecretpassword 0210010000 IRC|aBgH$ Z
```
Meaning: Password "moresecretpassword", version 2.10, capability flags "IRC|aBgH$", compression option "Z"

**Numeric Replies:**
- ERR_NEEDMOREPARAMS
- ERR_ALREADYREGISTRED

**Interpretation:**
The enhanced PASS command enables capability negotiation between servers, allowing servers to advertise their features and version before completing registration. This is critical for maintaining compatibility across different server implementations and versions. The version field allows graceful handling of protocol evolution, while the flags and options parameters enable feature negotiation (compression, anti-abuse, etc.).

---

### SERVER Message (Key Server-Specific Command)

**RFC 1459 Section 4.1.4:**
```
Command: SERVER
Parameters: <servername> <hopcount> <info>
```

**Purpose:**
- Register new server connection
- Propagate server introduction across network
- Build server topology tree

**Parameters:**
- `<servername>`: Fully qualified domain name of server
- `<hopcount>`: Distance from origin (local connection = 1, increments per hop)
- `<info>`: Free-form description of server

**Usage:**
1. New server introduces itself to its peer
2. Peer propagates SERVER message to all other connected servers
3. Each server updates its network topology map
4. Hopcount increments as message propagates

**Examples:**
```
SERVER test.oulu.fi 1 :Experimental server
  ; New server introducing itself (hopcount 1 = direct connection)

:tolsun.oulu.fi SERVER csd.bu.edu 5 :BU Central Server
  ; Server tolsun.oulu.fi announcing csd.bu.edu (5 hops away)
```

---

**RFC 2813 Section 4.1.2:**
```
Command: SERVER
Parameters: <servername> <hopcount> <token> <info>
```

**Major addition: `<token>` parameter**

**Token system (NEW in RFC 2813):**
- Numeric identifier for the server (integer)
- Used for efficient server references in other messages
- Replaces servername in NICK and SERVICE messages
- Reduces bandwidth (number vs string)
- Assigned by the server introducing the new server

**Enhanced error handling:**
- Errors typically sent via ERROR command (not numeric)
- Connection terminated for most SERVER errors
- Duplicate server detection (closes connection)
- Acyclic tree validation (prevents loops)

**Duplicate server detection:**
If a SERVER message introduces a server already known to the receiving server:
- Connection from which message arrived MUST be closed
- Indicates duplicate route (tree loop formed)
- May close the other connection instead (implementation-specific)
- Can indicate two servers with same name (human intervention required)
- Particularly insidious: can split network into isolated partitions

**Examples:**
```
SERVER test.oulu.fi 1 1 :Experimental server
  ; New server test.oulu.fi introducing itself with token "1"

:tolsun.oulu.fi SERVER csd.bu.edu 5 34 :BU Central Server
  ; Server tolsun.oulu.fi announcing csd.bu.edu (5 hops, token 34)
  ; Token "34" will be used when introducing users/services from csd.bu.edu
```

**Numeric Replies:**
- ERR_ALREADYREGISTRED

**Critical difference:**
The token system is the most significant enhancement. Instead of using full server names in every NICK/SERVICE message, the compact numeric token is used, significantly reducing protocol overhead in large networks.

**Why this matters:**
In a network with thousands of users joining, using "csd.bu.edu" (12 bytes) vs "34" (2 bytes) for every user introduction results in substantial bandwidth savings.

**Comparison:**
- RFC 1459: 3 parameters (name, hopcount, info)
- RFC 2813: 4 parameters (name, hopcount, **token**, info)
- The token is the key innovation for efficiency

---

### NICK Message (Server-to-Server Format)

**RFC 1459 Section 4.1.2 (Client NICK):**
```
Command: NICK
Parameters: <nickname> [ <hopcount> ]
```
- Used for both client registration and server-to-server propagation
- Optional hopcount parameter for server propagation
- Minimal information in server-to-server format
- Requires separate USER message for complete client information

**RFC 2813 Section 4.1.3 (Server NICK):**
```
Command: NICK
Parameters: <nickname> <hopcount> <username> <host> <servertoken> <umode> <realname>
```

**This is a completely different message format** - essentially combines NICK + USER + MODE into a single server-to-server message.

**Parameters:**

1. **`<nickname>`**: User's nickname
2. **`<hopcount>`**: Hops from user's server to current server (0 for local)
3. **`<username>`**: Username (ident)
4. **`<host>`**: Hostname or IP address
5. **`<servertoken>`**: Token of server user is connected to (from SERVER message)
6. **`<umode>`**: Initial user modes (e.g., "+i" for invisible)
7. **`<realname>`**: Real name / GECOS field

**Critical rule:**
This form MUST NOT be allowed from user connections. It's exclusively for server-to-server propagation.

**Hopcount behavior:**
- Local connection: hopcount = 0
- Incremented by each server as message propagates
- Indicates "distance" from user's home server

**Server token usage:**
Replaces the `<servername>` parameter from RFC 1459's USER command. Instead of sending the full server name, the compact numeric token is used.

**Example:**
```
NICK syrk 5 kalt millennium.stealth.net 34 +i :Christophe Kalt
  ; New user "syrk" (username: kalt)
  ; Connected from millennium.stealth.net
  ; To server token "34" (csd.bu.edu from earlier example)
  ; 5 hops away
  ; Invisible mode (+i)
  ; Real name: Christophe Kalt

:krys NICK syrk
  ; Nickname change (same format as client NICK in RFC 2812)
  ; krys changed nickname to syrk
```

**Two NICK formats in server protocol:**

1. **User introduction** (7 parameters): New user joining network
2. **Nickname change** (1 parameter): Existing user changing nick

Servers MUST distinguish between these based on parameter count.

**Efficiency gain:**
Combining NICK/USER/MODE into one message reduces:
- Number of messages (1 instead of 3)
- Parsing overhead
- Network bandwidth
- State synchronization complexity

**Comparison with client protocol:**
- **Client (RFC 2812)**: NICK, USER, MODE sent as 3 separate messages
- **Server (RFC 2813)**: All combined into single NICK with 7 parameters
- Client never sees the extended NICK format
- Server never accepts extended NICK from clients

---

### SERVICE Message (Server Introduction of Services)

**RFC 1459:**
**No SERVICE command existed in RFC 1459.**

Services (like NickServ, ChanServ) were implementation-specific and not part of the protocol specification. Only some service-related numeric replies existed (RPL_SERVICE, RPL_SERVICEINFO, etc.), but no standardized way to register services.

**RFC 2813 Section 4.1.4:**
```
Command: SERVICE
Parameters: <servicename> <servertoken> <distribution> <type> <hopcount> <info>
```

**This is a new addition** formalizing services in the protocol.

**Parameters:**

1. **`<servicename>`**: Name of the service (e.g., "dict@irc.fr")
2. **`<servertoken>`**: Token of server service is connected to
3. **`<distribution>`**: Service visibility mask (which servers can see it)
4. **`<type>`**: Service type (reserved for future use)
5. **`<hopcount>`**: Hops from service's server (like NICK)
6. **`<info>`**: Description of the service

**Purpose:**
Introduce a new service to the IRC network and propagate this information to other servers.

**Critical rule:**
This form SHOULD NOT be allowed from client connections. It MUST be used between servers to notify other servers of new services.

**Server token usage:**
Like the enhanced NICK message, SERVICE uses the server token to identify which server the service is connected to, reducing bandwidth.

**Distribution mask (KEY FEATURE):**
- Controls service visibility across network
- Service only known to servers matching the mask
- Network path between servers must all match mask
- "*" = no restriction (globally visible service)
- Example: "*.fr" = only visible to servers with names matching *.fr

**Hopcount:**
- Local connection: hopcount = 0
- Incremented by each server as propagated
- Indicates distance from service's home server

**Type parameter:**
Reserved for future usage. Currently not used but available for service categorization (e.g., nickname services, channel services, etc.).

**Example:**
```
SERVICE dict@irc.fr 9 *.fr 0 1 :French Dictionary
  ; Service "dict@irc.fr" registered on server token "9"
  ; Only available on servers matching "*.fr"
  ; Hopcount 1 (one hop away)
  ; Type 0 (reserved)
  ; Description: French Dictionary
```

**Numeric Replies:**
- ERR_ALREADYREGISTRED
- ERR_NEEDMOREPARAMS
- ERR_ERRONEUSNICKNAME
- RPL_YOURESERVICE
- RPL_YOURHOST
- RPL_MYINFO

**Why this matters:**
Before RFC 2813, services were bolted onto IRC without protocol support. This formalization:
1. Standardizes service introduction across the network
2. Enables service visibility control (distribution masks)
3. Allows services to be properly integrated into server topology
4. Provides framework for future service types
5. Uses token system for efficiency

**Comparison with RFC 2812:**
RFC 2812 Section 3.1.6 also has a SERVICE command, but with a completely different format meant for client registration as a service. This is somewhat confusing - the two SERVICE commands serve different purposes:
- **RFC 2812 (client)**: Service registering itself as a client
- **RFC 2813 (server)**: Server announcing a service to other servers

The RFC 2813 version is the real server-to-server service protocol.

---

### QUIT and SQUIT (Server Disconnect Handling)

**QUIT - RFC 1459 Section 4.1.6:**
```
Command: QUIT
Parameters: [<Quit Message>]
```

**Server behavior:**
- Server must close connection after receiving QUIT
- QUIT propagated to other servers for network-wide notification
- Special netsplit format: two server names separated by space
  - First name: server still connected
  - Second name: server that disconnected
- Server fills in quit message if client connection dies without QUIT
- Channel members must be notified when user quits

**QUIT - RFC 2813 Section 4.1.5:**
```
Command: QUIT
Parameters: [<Quit Message>]
```

**Enhancements:**

**Netsplit message format (formalized):**
```
<Quit Message> = ":" servername SPACE servername
```

**Server protection (NEW):**
Servers SHOULD NOT allow clients to use quit messages in the netsplit format. This prevents clients from forging netsplit messages for social engineering or ban evasion.

**Automatic QUIT generation:**
Server REQUIRED to generate QUIT if connection closes without client issuing QUIT.

---

**SQUIT - RFC 1459 Section 4.1.7:**
```
Command: SQUIT
Parameters: <server> <comment>
```

**Two uses:**
1. Operator breaking server link
2. Netsplit notification

**Requirements:**
- Both sides send SQUIT for all downstream servers
- QUIT messages for all downstream clients
- Update network topology

**SQUIT - RFC 2813 Section 4.1.6:**
```
Command: SQUIT
Parameters: <server> <comment>
```

**Enhancements:**

**QUIT propagation relaxed:**
- QUIT MAY be sent for downstream clients (was implicit MUST)
- Channel members MUST receive QUIT for lost users

**NEW: Nickname delay list:**
Server SHOULD add removed nicknames to temporarily unavailable list to prevent future collisions.

**This helps prevent nickname hijacking during netsplits.**

---

### Key Innovations Summary

| Feature | RFC 1459 | RFC 2813 |
|---------|----------|----------|
| **Server tokens** | Not present | Central efficiency feature |
| **Version negotiation** | Not supported | PASS version/flags/options |
| **NICK consolidation** | Separate NICK/USER | Combined 7-parameter NICK |
| **SERVICE command** | Did not exist | Formalized service protocol |
| **Netsplit protection** | Basic | Anti-forgery + nickname delay |
| **Capability flags** | Not supported | Compression, anti-abuse, etc. |

---

## RFC 2813 Section 4.1: Connection Registration (Server Protocol)

### Summary

This section compares server-to-server connection registration between RFC 1459 Section 4.1 and RFC 2813 Section 4.1, focusing on the commands specific to server protocol that were removed from RFC 2812 (the client protocol).

**RFC 1459 Section 4.1** combined both client and server connection registration in a single section, documenting how both types of connections establish themselves on the IRC network.

**RFC 2813 Section 4.1** focuses exclusively on server-to-server connection registration, extracting and expanding the server-specific portions from RFC 1459.

**Key distinction:**
- **Client registration**: PASS (optional) → NICK → USER
- **Server registration**: PASS (required) → SERVER

The server protocol uses enhanced versions of NICK and SERVICE to propagate new users and services across the server mesh, rather than the separate NICK/USER messages used by clients.

---

### PASS Message (Server Password Handling)

**RFC 1459 Section 4.1.1:**
```
Command: PASS
Parameters: <password>
```
- Single password parameter
- MUST be sent before SERVER command (for servers)
- Only last PASS before registration is used
- Simple password verification
- Multiple PASS commands allowed before registration, but only last one counts

**RFC 2813 Section 4.1.1:**
```
Command: PASS
Parameters: <password> <version> <flags> [<options>]
```

**Major enhancements:**

1. **`<version>`** parameter (NEW):
   - Format: 4 digits + 6 digits (e.g., "0210010000")
   - First 4 digits: Protocol version (0210 = version 2.10)
   - Last 6 digits: Implementation-specific flags
   - Enables version negotiation between servers

2. **`<flags>`** parameter (NEW):
   - Capability flags indicating server features
   - Format: alphanumeric string with special characters
   - Example: "IRC|aBgH$" indicates various capabilities
   - Enables feature negotiation during connection

3. **`<options>`** parameter (NEW, optional):
   - Extended server capabilities
   - Format varies by implementation
   - Examples: "Z" for compression, "P" for anti-abuse protections
   - Future extensibility for new features

**Stricter requirements:**
- PASS MUST be sent before SERVER (not optional for servers)
- Only ONE (1) PASS command SHALL be accepted
- Last three (3) parameters MUST be ignored if received from client
- Better version compatibility checking

**Example:**
```
PASS moresecretpassword 0210010000 IRC|aBgH$ Z
```
Meaning: Password "moresecretpassword", version 2.10, capability flags "IRC|aBgH$", compression option "Z"

**Numeric Replies:**
- ERR_NEEDMOREPARAMS
- ERR_ALREADYREGISTRED

**Interpretation:**
The enhanced PASS command enables capability negotiation between servers, allowing servers to advertise their features and version before completing registration. This is critical for maintaining compatibility across different server implementations and versions. The version field allows graceful handling of protocol evolution, while the flags and options parameters enable feature negotiation (compression, anti-abuse, etc.).

---

### SERVER Message (Key Server-Specific Command)

**RFC 1459 Section 4.1.4:**
```
Command: SERVER
Parameters: <servername> <hopcount> <info>
```

**Purpose:**
- Register new server connection
- Propagate server introduction across network
- Build server topology tree

**Parameters:**
- `<servername>`: Fully qualified domain name of server
- `<hopcount>`: Distance from origin (local connection = 1, increments per hop)
- `<info>`: Free-form description of server

**Usage:**
1. New server introduces itself to its peer
2. Peer propagates SERVER message to all other connected servers
3. Each server updates its network topology map
4. Hopcount increments as message propagates

**Examples:**
```
SERVER test.oulu.fi 1 :Experimental server
  ; New server introducing itself (hopcount 1 = direct connection)

:tolsun.oulu.fi SERVER csd.bu.edu 5 :BU Central Server
  ; Server tolsun.oulu.fi announcing csd.bu.edu (5 hops away)
```

**RFC 2813 Section 4.1.2:**
```
Command: SERVER
Parameters: <servername> <hopcount> <token> <info>
```

**Major addition: `<token>` parameter**

**Token system (NEW in RFC 2813):**
- Numeric identifier for the server (integer)
- Used for efficient server references in other messages
- Replaces servername in NICK and SERVICE messages
- Reduces bandwidth (number vs string)
- Assigned by the server introducing the new server

**Enhanced error handling:**
- Errors typically sent via ERROR command (not numeric)
- Connection terminated for most SERVER errors
- Duplicate server detection (closes connection)
- Acyclic tree validation (prevents loops)

**Duplicate server detection:**
If a SERVER message introduces a server already known to the receiving server:
- Connection from which message arrived MUST be closed
- Indicates duplicate route (tree loop formed)
- May close the other connection instead (implementation-specific)
- Can indicate two servers with same name (human intervention required)
- Particularly insidious: can split network into isolated partitions

**Examples:**
```
SERVER test.oulu.fi 1 1 :Experimental server
  ; New server test.oulu.fi introducing itself with token "1"

:tolsun.oulu.fi SERVER csd.bu.edu 5 34 :BU Central Server
  ; Server tolsun.oulu.fi announcing csd.bu.edu (5 hops, token 34)
  ; Token "34" will be used when introducing users/services from csd.bu.edu
```

**Numeric Replies:**
- ERR_ALREADYREGISTRED

**Critical difference:**
The token system is the most significant enhancement. Instead of using full server names in every NICK/SERVICE message, the compact numeric token is used, significantly reducing protocol overhead in large networks.

**Why this matters:**
In a network with thousands of users joining, using "csd.bu.edu" (12 bytes) vs "34" (2 bytes) for every user introduction results in substantial bandwidth savings.

**Comparison:**
- RFC 1459: 3 parameters (name, hopcount, info)
- RFC 2813: 4 parameters (name, hopcount, **token**, info)
- The token is the key innovation for efficiency

---

### NICK Message (Server-to-Server Format)

**RFC 1459 Section 4.1.2 (Client NICK):**
```
Command: NICK
Parameters: <nickname> [ <hopcount> ]
```
- Used for both client registration and server-to-server propagation
- Optional hopcount parameter for server propagation
- Minimal information in server-to-server format
- Requires separate USER message for complete client information

**RFC 2813 Section 4.1.3 (Server NICK):**
```
Command: NICK
Parameters: <nickname> <hopcount> <username> <host> <servertoken> <umode> <realname>
```

**This is a completely different message format** - essentially combines NICK + USER + MODE into a single server-to-server message.

**Parameters:**

1. **`<nickname>`**: User's nickname
2. **`<hopcount>`**: Hops from user's server to current server (0 for local)
3. **`<username>`**: Username (ident)
4. **`<host>`**: Hostname or IP address
5. **`<servertoken>`**: Token of server user is connected to (from SERVER message)
6. **`<umode>`**: Initial user modes (e.g., "+i" for invisible)
7. **`<realname>`**: Real name / GECOS field

**Critical rule:**
This form MUST NOT be allowed from user connections. It's exclusively for server-to-server propagation.

**Hopcount behavior:**
- Local connection: hopcount = 0
- Incremented by each server as message propagates
- Indicates "distance" from user's home server

**Server token usage:**
Replaces the `<servername>` parameter from RFC 1459's USER command. Instead of sending the full server name, the compact numeric token is used.

**Example:**
```
NICK syrk 5 kalt millennium.stealth.net 34 +i :Christophe Kalt
  ; New user "syrk" (username: kalt)
  ; Connected from millennium.stealth.net
  ; To server token "34" (csd.bu.edu from earlier example)
  ; 5 hops away
  ; Invisible mode (+i)
  ; Real name: Christophe Kalt

:krys NICK syrk
  ; Nickname change (same format as client NICK in RFC 2812)
  ; krys changed nickname to syrk
```

**Two NICK formats in server protocol:**

1. **User introduction** (7 parameters): New user joining network
2. **Nickname change** (1 parameter): Existing user changing nick

Servers MUST distinguish between these based on parameter count.

**Efficiency gain:**
Combining NICK/USER/MODE into one message reduces:
- Number of messages (1 instead of 3)
- Parsing overhead
- Network bandwidth
- State synchronization complexity

**Comparison with client protocol:**
- **Client (RFC 2812)**: NICK, USER, MODE sent as 3 separate messages
- **Server (RFC 2813)**: All combined into single NICK with 7 parameters
- Client never sees the extended NICK format
- Server never accepts extended NICK from clients

---

### SERVICE Message (Server Introduction of Services)

**RFC 1459:**
**No SERVICE command existed in RFC 1459.**

Services (like NickServ, ChanServ) were implementation-specific and not part of the protocol specification. Only some service-related numeric replies existed (RPL_SERVICE, RPL_SERVICEINFO, etc.), but no standardized way to register services.

**RFC 2813 Section 4.1.4:**
```
Command: SERVICE
Parameters: <servicename> <servertoken> <distribution> <type> <hopcount> <info>
```

**This is a new addition** formalizing services in the protocol.

**Parameters:**

1. **`<servicename>`**: Name of the service (e.g., "dict@irc.fr")
2. **`<servertoken>`**: Token of server service is connected to
3. **`<distribution>`**: Service visibility mask (which servers can see it)
4. **`<type>`**: Service type (reserved for future use)
5. **`<hopcount>`**: Hops from service's server (like NICK)
6. **`<info>`**: Description of the service

**Purpose:**
Introduce a new service to the IRC network and propagate this information to other servers.

**Critical rule:**
This form SHOULD NOT be allowed from client connections. It MUST be used between servers to notify other servers of new services.

**Server token usage:**
Like the enhanced NICK message, SERVICE uses the server token to identify which server the service is connected to, reducing bandwidth.

**Distribution mask (KEY FEATURE):**
- Controls service visibility across network
- Service only known to servers matching the mask
- Network path between servers must all match mask
- "*" = no restriction (globally visible service)
- Example: "*.fr" = only visible to servers with names matching *.fr

**Hopcount:**
- Local connection: hopcount = 0
- Incremented by each server as propagated
- Indicates distance from service's home server

**Type parameter:**
Reserved for future usage. Currently not used but available for service categorization (e.g., nickname services, channel services, etc.).

**Example:**
```
SERVICE dict@irc.fr 9 *.fr 0 1 :French Dictionary
  ; Service "dict@irc.fr" registered on server token "9"
  ; Only available on servers matching "*.fr"
  ; Hopcount 1 (one hop away)
  ; Type 0 (reserved)
  ; Description: French Dictionary
```

**Numeric Replies:**
- ERR_ALREADYREGISTRED
- ERR_NEEDMOREPARAMS
- ERR_ERRONEUSNICKNAME
- RPL_YOURESERVICE
- RPL_YOURHOST
- RPL_MYINFO

**Why this matters:**
Before RFC 2813, services were bolted onto IRC without protocol support. This formalization:
1. Standardizes service introduction across the network
2. Enables service visibility control (distribution masks)
3. Allows services to be properly integrated into server topology
4. Provides framework for future service types
5. Uses token system for efficiency

**Comparison with RFC 2812:**
RFC 2812 Section 3.1.6 also has a SERVICE command, but with a completely different format meant for client registration as a service. This is somewhat confusing - the two SERVICE commands serve different purposes:
- **RFC 2812 (client)**: Service registering itself as a client
- **RFC 2813 (server)**: Server announcing a service to other servers

The RFC 2813 version is the real server-to-server service protocol.

---

### QUIT and SQUIT (Server Disconnect Handling)

**QUIT - RFC 1459 Section 4.1.6:**
```
Command: QUIT
Parameters: [<Quit Message>]
```

**Server behavior:**
- Server must close connection after receiving QUIT
- QUIT propagated to other servers for network-wide notification
- Special netsplit format: two server names separated by space
  - First name: server still connected
  - Second name: server that disconnected
- Server fills in quit message if client connection dies without QUIT
- Channel members must be notified when user quits

**QUIT - RFC 2813 Section 4.1.5:**
```
Command: QUIT
Parameters: [<Quit Message>]
```

**Enhancements:**

**Netsplit message format (formalized):**
```
<Quit Message> = ":" servername SPACE servername
```

**Server protection (NEW):**
Servers SHOULD NOT allow clients to use quit messages in the netsplit format. This prevents clients from forging netsplit messages for social engineering or ban evasion.

**Automatic QUIT generation:**
Server REQUIRED to generate QUIT if connection closes without client issuing QUIT.

---

**SQUIT - RFC 1459 Section 4.1.7:**
```
Command: SQUIT
Parameters: <server> <comment>
```

**Two uses:**
1. Operator breaking server link
2. Netsplit notification

**Requirements:**
- Both sides send SQUIT for all downstream servers
- QUIT messages for all downstream clients
- Update network topology

**SQUIT - RFC 2813 Section 4.1.6:**
```
Command: SQUIT
Parameters: <server> <comment>
```

**Enhancements:**

**QUIT propagation relaxed:**
- QUIT MAY be sent for downstream clients (was implicit MUST)
- Channel members MUST receive QUIT for lost users

**NEW: Nickname delay list:**
Server SHOULD add removed nicknames to temporarily unavailable list to prevent future collisions.

**This helps prevent nickname hijacking during netsplits.**

---

### Summary Table

| Command | RFC 1459 Parameters | RFC 2813 Parameters | Key Innovation |
|---------|---------------------|---------------------|----------------|
| **PASS** | 1 (password) | 4 (password, version, flags, options) | Version/capability negotiation |
| **SERVER** | 3 (name, hopcount, info) | 4 (name, hopcount, **token**, info) | Token system for efficiency |
| **NICK** | 2 (nick, hopcount) | 7 (nick, hop, user, host, **token**, mode, name) | Message consolidation |
| **SERVICE** | Did not exist | 6 (name, **token**, dist, type, hop, info) | Formalized service protocol |
| **QUIT** | Informal netsplit format | Formalized + anti-forgery | Protection against fake netsplits |
| **SQUIT** | Implicit client QUITs | Optional QUITs + nickname delay | Collision prevention |

---

### Interpretation

The evolution from RFC 1459 to RFC 2813 represents maturation of the server protocol through operational experience (1993-2000):

**Key innovations:**

1. **Token system**: Most significant efficiency improvement
   - Reduces bandwidth by ~80% for server references
   - Critical for scaling to large networks

2. **Message consolidation**: NICK combines 3 messages into 1
   - 66% reduction in user introduction overhead
   - Simpler state synchronization

3. **Service formalization**: Services become first-class protocol entities
   - Distribution masks enable service scoping
   - Integration into network topology

4. **Version negotiation**: PASS enables capability detection
   - Graceful handling of protocol evolution
   - Feature negotiation (compression, anti-abuse)

5. **Netsplit protection**: Multiple enhancements
   - Anti-forgery for QUIT messages
   - Nickname delay list prevents collisions
   - Relaxed but clearer SQUIT requirements

**Backward compatibility maintained** despite enhancements, allowing gradual network upgrades.

---
