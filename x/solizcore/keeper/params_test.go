package keeper_test

import (
	"testing"

	"github.com/stretchr/testify/require"

	keepertest "soliz-core/testutil/keeper"
	"soliz-core/x/solizcore/types"
)

func TestGetParams(t *testing.T) {
	k, ctx := keepertest.SolizcoreKeeper(t)
	params := types.DefaultParams()

	require.NoError(t, k.SetParams(ctx, params))
	require.EqualValues(t, params, k.GetParams(ctx))
}
