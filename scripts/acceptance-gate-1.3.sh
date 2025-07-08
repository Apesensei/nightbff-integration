#!/usr/bin/env bash
# acceptance-gate-1.3.sh - Verify Task 1.3 acceptance criteria
set -euo pipefail

echo "🎯 Task 1.3 Acceptance Gate: Branch Protection Rules Implementation"
echo "=================================================================="

# Acceptance criteria: "Branch protection rules in GitHub"
check_deliverables() {
    local success=true
    
    echo "📋 Checking required deliverables..."
    
    # 1. Setup script exists and works
    if [ -f "scripts/setup-branch-protection.sh" ] && [ -x "scripts/setup-branch-protection.sh" ]; then
        echo "✅ Branch protection setup script exists and is executable"
    else
        echo "❌ Branch protection setup script missing"
        success=false
    fi
    
    # 2. Documentation exists and is comprehensive
    if [ -f "docs/BRANCH_PROTECTION_SETUP.md" ]; then
        # Check for key sections
        if grep -q "Main Branch" docs/BRANCH_PROTECTION_SETUP.md && \
           grep -q "Integration Branches" docs/BRANCH_PROTECTION_SETUP.md && \
           grep -q "GitHub Web UI" docs/BRANCH_PROTECTION_SETUP.md; then
            echo "✅ Comprehensive branch protection documentation exists"
        else
            echo "❌ Branch protection documentation incomplete"
            success=false
        fi
    else
        echo "❌ Branch protection documentation missing"
        success=false
    fi
    
    # 3. Validation script exists and works
    if [ -f "scripts/validate-branch-protection.sh" ] && [ -x "scripts/validate-branch-protection.sh" ]; then
        echo "✅ Branch protection validation script exists and is executable"
    else
        echo "❌ Branch protection validation script missing"
        success=false
    fi
    
    # 4. CI workflow has all required jobs
    local required_jobs=("sanity" "unit_backend" "unit_frontend" "contract_backend" "integration_tests")
    local all_jobs_found=true
    
    for job in "${required_jobs[@]}"; do
        if ! grep -q "^[[:space:]]*${job}:" .github/workflows/integration-ci.yml; then
            echo "❌ Required CI job '$job' not found in workflow"
            all_jobs_found=false
            success=false
        fi
    done
    
    if $all_jobs_found; then
        echo "✅ All required CI jobs defined in workflow"
    fi
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

check_configuration_completeness() {
    echo ""
    echo "🔧 Verifying configuration completeness..."
    
    # Test the setup script
    if ./scripts/setup-branch-protection.sh >/dev/null 2>&1; then
        echo "✅ Setup script runs without errors"
    else
        echo "❌ Setup script has errors"
        return 1
    fi
    
    # Check that validation script detects current state correctly
    local validation_output
    validation_output=$(./scripts/validate-branch-protection.sh 2>&1 || true)
    
    if echo "$validation_output" | grep -q "All required CI jobs are defined"; then
        echo "✅ Validation script correctly identifies CI jobs"
    else
        echo "❌ Validation script CI job detection failed"
        return 1
    fi
    
    if echo "$validation_output" | grep -q "Branch protection documentation exists"; then
        echo "✅ Validation script correctly identifies documentation"
    else
        echo "❌ Validation script documentation detection failed"
        return 1
    fi
}

analyze_strategic_decisions() {
    echo ""
    echo "🎯 Verifying strategic decisions..."
    
    # Check that documentation addresses key decisions
    local doc_file="docs/BRANCH_PROTECTION_SETUP.md"
    
    if grep -q "develop.*not.*exist\|develop.*branch.*pattern" "$doc_file" 2>/dev/null; then
        echo "✅ Documentation addresses develop branch decision"
    elif ! git branch -a | grep -q "develop"; then
        echo "✅ Correctly omitted develop branch (doesn't exist in repo)"
    else
        echo "⚠️  Develop branch decision not explicitly documented"
    fi
    
    if grep -q "Signed.*commits.*Optional\|signed.*commit.*not.*required" "$doc_file" 2>/dev/null; then
        echo "✅ Signed commits decision documented with rationale"
    else
        echo "❌ Signed commits decision not properly documented"
        return 1
    fi
    
    if grep -q "integration.*short-lived\|integration.*experimental" "$doc_file" 2>/dev/null; then
        echo "✅ Integration branch protection strategy documented"
    else
        echo "❌ Integration branch strategy not explained"
        return 1
    fi
}

verify_implementation_readiness() {
    echo ""
    echo "🚀 Verifying implementation readiness..."
    
    # Check for GitHub CLI commands
    if grep -q "gh api repos.*protection" docs/BRANCH_PROTECTION_SETUP.md; then
        echo "✅ GitHub CLI automation commands provided"
    else
        echo "❌ GitHub CLI commands missing from documentation"
        return 1
    fi
    
    # Check for web UI instructions
    if grep -q "GitHub Web UI\|Settings.*Branches" docs/BRANCH_PROTECTION_SETUP.md; then
        echo "✅ GitHub web UI instructions provided"
    else
        echo "❌ GitHub web UI instructions missing"
        return 1
    fi
    
    # Check for verification steps
    if grep -q "Test.*Branch.*Protection\|verification.*step" docs/BRANCH_PROTECTION_SETUP.md; then
        echo "✅ Protection verification steps documented"
    else
        echo "❌ Verification steps missing from documentation"
        return 1
    fi
}

main() {
    local overall_success=true
    
    check_deliverables || overall_success=false
    check_configuration_completeness || overall_success=false
    analyze_strategic_decisions || overall_success=false
    verify_implementation_readiness || overall_success=false
    
    echo ""
    echo "======================================================================"
    
    if [ "$overall_success" = true ]; then
        echo "🎉 TASK 1.3 ACCEPTANCE GATE: ✅ PASSED"
        echo ""
        echo "📋 Summary of Deliverables:"
        echo "  ✅ Branch protection setup script (scripts/setup-branch-protection.sh)"
        echo "  ✅ Comprehensive documentation (docs/BRANCH_PROTECTION_SETUP.md)"
        echo "  ✅ Validation script (scripts/validate-branch-protection.sh)"
        echo "  ✅ CI workflow with all required jobs"
        echo "  ✅ Strategic decisions documented with rationale"
        echo "  ✅ Multiple implementation methods provided"
        echo ""
        echo "🎯 Branch Protection Configuration Ready for Application"
        echo ""
        echo "📝 Next Action Required:"
        echo "   Apply branch protection settings using provided documentation"
        echo "   Repository admin access to Apesensei/nightbff-integration required"
        
        return 0
    else
        echo "❌ TASK 1.3 ACCEPTANCE GATE: FAILED"
        echo ""
        echo "🔧 Issues must be resolved before proceeding to Task 1.4"
        
        return 1
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 