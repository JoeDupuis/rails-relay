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

