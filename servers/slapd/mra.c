/* $OpenLDAP$ */
/*
 * Copyright 1998-2002 The OpenLDAP Foundation, All Rights Reserved.
 * COPYING RESTRICTIONS APPLY, see COPYRIGHT file
 */
/* mra.c - routines for dealing with extensible matching rule assertions */

#include "portable.h"

#include <stdio.h>

#include <ac/string.h>
#include <ac/socket.h>

#include "slap.h"


void
mra_free(
	MatchingRuleAssertion *mra,
	int	freeit
)
{
	ch_free( mra->ma_value.bv_val );
	if ( freeit ) {
		ch_free( (char *) mra );
	}
}

int
get_mra(
	BerElement	*ber,
	MatchingRuleAssertion	**mra,
	const char **text
)
{
	int rc, tag;
	ber_len_t length;
	struct berval type = { 0, NULL }, value;
	MatchingRuleAssertion *ma;

	ma = ch_malloc( sizeof( MatchingRuleAssertion ) );
	ma->ma_rule = NULL;
	ma->ma_rule_text.bv_len = 0;
	ma->ma_rule_text.bv_val = NULL;
	ma->ma_desc = NULL;
	ma->ma_dnattrs = 0;
	ma->ma_value.bv_len = 0;
	ma->ma_value.bv_val = NULL;

	rc = ber_scanf( ber, "{t", &tag );

	if( rc == LBER_ERROR ) {
#ifdef NEW_LOGGING
		LDAP_LOG(( "operation", LDAP_LEVEL_ERR,
			   "get_mra: ber_scanf (\"{t\") failure\n" ));
#else
		Debug( LDAP_DEBUG_ANY, "  get_mra ber_scanf\n", 0, 0, 0 );
#endif

		*text = "Error parsing matching rule assertion";
		mra_free( ma, 1 );
		return SLAPD_DISCONNECT;
	}

	if ( tag == LDAP_FILTER_EXT_OID ) {
		rc = ber_scanf( ber, "m", &ma->ma_rule_text );
		if ( rc == LBER_ERROR ) {
#ifdef NEW_LOGGING
			LDAP_LOG(( "operation", LDAP_LEVEL_ERR,
				   "get_mra: ber_scanf(\"o\") failure.\n" ));
#else
			Debug( LDAP_DEBUG_ANY, "  get_mra ber_scanf for mr\n", 0, 0, 0 );
#endif

			*text = "Error parsing matching rule in matching rule assertion";
			mra_free( ma, 1 );
			return SLAPD_DISCONNECT;
		}

		rc = ber_scanf( ber, "t", &tag );
		if( rc == LBER_ERROR ) {
#ifdef NEW_LOGGING
			LDAP_LOG(( "operation", LDAP_LEVEL_ERR,
				   "get_mra: ber_scanf (\"t\") failure\n" ));
#else
			Debug( LDAP_DEBUG_ANY, "  get_mra ber_scanf\n", 0, 0, 0 );
#endif

			*text = "Error parsing matching rule assertion";
			mra_free( ma, 1 );
			return SLAPD_DISCONNECT;
		}
	}

	if ( tag == LDAP_FILTER_EXT_TYPE ) {
		rc = ber_scanf( ber, "m", &type );
		if ( rc == LBER_ERROR ) {
#ifdef NEW_LOGGING
			LDAP_LOG(( "operation", LDAP_LEVEL_ERR,
				   "get_mra: ber_scanf (\"o\") failure.\n" ));
#else
			Debug( LDAP_DEBUG_ANY, "  get_mra ber_scanf for ad\n", 0, 0, 0 );
#endif

			*text = "Error parsing attribute description in matching rule assertion";
			return SLAPD_DISCONNECT;
		}

		rc = ber_scanf( ber, "t", &tag );
		if( rc == LBER_ERROR ) {
#ifdef NEW_LOGGING
			LDAP_LOG(( "operation", LDAP_LEVEL_ERR,
				   "get_mra: ber_scanf (\"t\") failure.\n" ));
#else
			Debug( LDAP_DEBUG_ANY, "  get_mra ber_scanf\n", 0, 0, 0 );
#endif

			*text = "Error parsing matching rule assertion";
			mra_free( ma, 1 );
			return SLAPD_DISCONNECT;
		}
	}

	if ( tag != LDAP_FILTER_EXT_VALUE ) {
#ifdef NEW_LOGGING
		LDAP_LOG(( "operation", LDAP_LEVEL_ERR,
			   "get_mra: ber_scanf missing value\n" ));
#else
		Debug( LDAP_DEBUG_ANY, "  get_mra ber_scanf missing value\n", 0, 0, 0 );
#endif

		*text = "Missing value in matching rule assertion";
		mra_free( ma, 1 );
		return SLAPD_DISCONNECT;
	}

	rc = ber_scanf( ber, "m", &value );

	if( rc == LBER_ERROR ) {
#ifdef NEW_LOGGING
		LDAP_LOG(( "operation", LDAP_LEVEL_ERR,
			   "get_mra: ber_scanf (\"o\") failure.\n" ));
#else
		Debug( LDAP_DEBUG_ANY, "  get_mra ber_scanf\n", 0, 0, 0 );
#endif

		*text = "Error decoding value in matching rule assertion";
		mra_free( ma, 1 );
		return SLAPD_DISCONNECT;
	}

	tag = ber_peek_tag( ber, &length );

	if ( tag == LDAP_FILTER_EXT_DNATTRS ) {
		rc = ber_scanf( ber, "b}", &ma->ma_dnattrs );
	} else {
		rc = ber_scanf( ber, "}" );
	}

	if( rc == LBER_ERROR ) {
#ifdef NEW_LOGGING
		LDAP_LOG(( "operation", LDAP_LEVEL_ERR,
			   "get_mra: ber_scanf failure\n"));
#else
		Debug( LDAP_DEBUG_ANY, "  get_mra ber_scanf\n", 0, 0, 0 );
#endif

		*text = "Error decoding dnattrs matching rule assertion";
		mra_free( ma, 1 );
		return SLAPD_DISCONNECT;
	}

	if( ma->ma_dnattrs ) {
		*text = "matching with \":dn\" not supported";
		return LDAP_INAPPROPRIATE_MATCHING;
	}

	if( type.bv_val != NULL ) {
		rc = slap_bv2ad( &type, &ma->ma_desc, text );
		if( rc != LDAP_SUCCESS ) {
			mra_free( ma, 1 );
			return rc;
		}

	} else {
		*text = "matching without attribute description rule not supported";
		return LDAP_INAPPROPRIATE_MATCHING;
	}

	if( ma->ma_rule_text.bv_val != NULL ) {
		ma->ma_rule = mr_bvfind( &ma->ma_rule_text );
		if( ma->ma_rule == NULL ) {
			mra_free( ma, 1 );
			*text = "matching rule not recognized";
			return LDAP_INAPPROPRIATE_MATCHING;
		}
	}

	if( ma->ma_desc != NULL &&
		ma->ma_desc->ad_type->sat_equality != NULL &&
		ma->ma_desc->ad_type->sat_equality->smr_usage & SLAP_MR_EXT )
	{
		/* no matching rule was provided, use the attribute's
		   equality rule if it supports extensible matching. */
		ma->ma_rule = ma->ma_desc->ad_type->sat_equality;

	} else {
		mra_free( ma, 1 );
		return LDAP_INAPPROPRIATE_MATCHING;
	}

	/* check to see if the matching rule is appropriate for
	   the syntax of the attribute.  This check will need
	   to be extended to support other kinds of extensible
	   matching rules */
	if( strcmp( ma->ma_rule->smr_syntax->ssyn_oid,
		ma->ma_desc->ad_type->sat_syntax->ssyn_oid ) != 0 )
	{
		mra_free( ma, 1 );
		return LDAP_INAPPROPRIATE_MATCHING;
	}

	/*
	 * OK, if no matching rule, normalize for equality, otherwise
	 * normalize for the matching rule.
	 */
	rc = value_validate_normalize( ma->ma_desc, SLAP_MR_EQUALITY,
		&value, &ma->ma_value, text );

	if( rc != LDAP_SUCCESS ) {
		mra_free( ma, 1 );
		return rc;
	}

	*mra = ma;
	return LDAP_SUCCESS;
}

