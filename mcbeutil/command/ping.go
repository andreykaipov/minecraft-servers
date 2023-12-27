package command

import (
	"encoding/json"
	"fmt"
	"regexp"
	"time"

	"github.com/sandertv/go-raknet"
)

type Ping struct {
	Host    string        `required:"" name:"host" help:"Host to ping, without the port, e.g. mc.host.com."`
	Port    string        `name:"port" help:"Port to ping on." default:"19132"`
	Timeout time.Duration `name:"timeout" help:"Timeout for the ping." default:"5s"`
}

// https://wiki.bedrock.dev/servers/raknet-and-mcpe.html:
//
// 0x1c | client alive time in ms (recorded from previous ping) | server GUID | string length |
// Edition (MCPE or MCEE for Education Edition) ; MOTD line 1      ; Protocol Version ; Version Name ; Player Count ; Max Player Count ; Server Unique ID     ; MOTD line 2   ; Game mode ; Game mode (numeric) ; Port (IPv4) ; Port (IPv6) ;
// MCPE                                         ; Dedicated Server ; 527              ; 1.19.1       ; 0            ; 10               ; 13253860892328930865 ; Bedrock level ; Survival  ; 1                   ; 19132       ; 19133       ;
//
// praise Copilot:
var pongRegex = regexp.MustCompile("(?P<edition>MCPE|MCEE);(?P<serverName>[^;]+);(?P<protocolVersion>[^;]+);(?P<versionName>[^;]+);(?P<playerCount>[^;]+);(?P<maxPlayerCount>[^;]+);(?P<serverUniqueID>[^;]+);(?P<worldName>[^;]+);(?P<gameMode>[^;]+);(?P<gameModeNumeric>[^;]+);(?P<portIPv4>[^;]+);(?P<portIPv6>[^;]+);(?P<remaining>.+)")

type Pong struct {
	Edition         string `json:"edition"`
	ServerName      string `json:"serverName"` // The MOTD (line 1) of the server (i.e. server-name in server.properties)
	ProtocolVersion string `json:"protocolVersion"`
	VersionName     string `json:"versionName"`
	PlayerCount     uint32 `json:"playerCount,string"`
	MaxPlayerCount  uint32 `json:"maxPlayerCount,string"`
	ServerUniqueID  uint64 `json:"serverUniqueID,string"`
	WorldName       string `json:"worldName"` // The MOTD (line 2) of the server (i.e. level-name in server.properties)
	GameMode        string `json:"gameMode"`
	GameModeNumeric uint32 `json:"gameModeNumeric,string"`
	PortIPv4        uint16 `json:"portIPv4,string"`
	PortIPv6        uint16 `json:"portIPv6,string"`
	Remaining       string `json:"remaining"`
}

func (c *Ping) Run() error {
	addr := fmt.Sprintf("%s:%s", c.Host, c.Port)
	data, err := raknet.PingTimeout(addr, c.Timeout)
	if err != nil {
		return err
	}

	pong := map[string]string{}
	matches := pongRegex.FindStringSubmatch(string(data))
	for i, name := range pongRegex.SubexpNames() {
		if i != 0 && name != "" {
			pong[name] = matches[i]
		}
	}

	pretty, err := json.MarshalIndent(pong, "", "  ")
	if err != nil {
		return err
	}
	fmt.Printf("%s\n", pretty)
	return nil
}
