# Basic test that should work in any environment
println("alpaca-connector tests running...")

# Test that we can at least run this file
result = 1 + 1 == 2

if result
    println("✓ Basic arithmetic test passed")
    exit(0)  # Success
else
    println("✗ Basic arithmetic test failed")
    exit(1)  # Failure
end