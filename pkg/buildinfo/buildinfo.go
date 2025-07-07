/*
 * Copyright (c) 2023 F5 Inc. All rights reserved.
 * Use of this source code is governed by the Apache License that can be found in the LICENSE file.
 */

package buildinfo

var semVer string

// SemVer is the version number of this build as provided by build pipeline
func SemVer() string {
	return semVer
}

var shortHash string

// ShortHash is the 8 char git shorthash
func ShortHash() string {
	return shortHash
}
