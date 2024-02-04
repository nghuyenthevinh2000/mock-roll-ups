package types

const (
	// ModuleName defines the module name
	ModuleName = "solizcore"

	// StoreKey defines the primary module store key
	StoreKey = ModuleName

	// MemStoreKey defines the in-memory store key
	MemStoreKey = "mem_solizcore"
)

var (
	ParamsKey = []byte("p_solizcore")
)

func KeyPrefix(p string) []byte {
	return []byte(p)
}
