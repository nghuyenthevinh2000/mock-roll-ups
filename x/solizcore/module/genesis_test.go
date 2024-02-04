package solizcore_test

import (
	"testing"

	"github.com/stretchr/testify/require"
	keepertest "soliz-core/testutil/keeper"
	"soliz-core/testutil/nullify"
	"soliz-core/x/solizcore/module"
	"soliz-core/x/solizcore/types"
)

func TestGenesis(t *testing.T) {
	genesisState := types.GenesisState{
		Params: types.DefaultParams(),

		// this line is used by starport scaffolding # genesis/test/state
	}

	k, ctx := keepertest.SolizcoreKeeper(t)
	solizcore.InitGenesis(ctx, k, genesisState)
	got := solizcore.ExportGenesis(ctx, k)
	require.NotNil(t, got)

	nullify.Fill(&genesisState)
	nullify.Fill(got)

	// this line is used by starport scaffolding # genesis/test/assert
}
