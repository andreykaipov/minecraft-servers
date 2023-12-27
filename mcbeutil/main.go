package main

import (
	"github.com/alecthomas/kong"
	"github.com/andreykaipov/minecraft-servers/mcbeutil/command"
)

type cli struct {
	Ping command.Ping `cmd:"" help:"Ping a server."`
}

func main() {
	ctx := kong.Parse(
		&cli{},
		kong.Name("mcbeutil"),
		kong.Description("Minecraft server utilities."),
		kong.ConfigureHelp(kong.HelpOptions{Compact: true}),
	)
	err := ctx.Run()
	ctx.FatalIfErrorf(err)
}
