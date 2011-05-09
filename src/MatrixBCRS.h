/*
 * MatrixBCRS.h
 *
 *  Created on: Oct 16, 2009
 *      Author: goto
 */

#ifndef MATRIXBCRS_H_
#define MATRIXBCRS_H_

#include "TypeDef.h"
#include "Matrix.h"
#include <vector>
#include <boost/numeric/ublas/matrix.hpp>
using namespace boost::numeric;

namespace pmw
{
class CMesh;

class CMatrixBCRS: public CMatrix
{
public:
	CMatrixBCRS(CMesh *pMesh, const uint& nDOF);
	virtual ~CMatrixBCRS();

        int Matrix_Add_Nodal(const uint& iNodeID, const uint& jNodeID, const double* NodalMatrix);
	int Matrix_Add_Elem(CMesh *pMesh, const uint& iElem, double *ElemMatrix);
        
        void Matrix_Clear();// Matrix 0 clear (非線形の行列更新の準備)
        
	virtual void multVector(CVector *pV, CVector *pP) const;
	void setValue(int inode, int idof, double value);

	int setupPreconditioner(int type);
	int setupSmoother(int type);

	double inverse(ublas::matrix<double> pA, ublas::matrix<double> *pB);
	double determinant(ublas::matrix<double> pA);
	void transpose(ublas::matrix<double> pA, ublas::matrix<double> *pB);
	void print_elem(ublas::matrix<double> pA);

	int precond(const CVector *pR, CVector *pZ) const;
	int relax(const CVector *pF, CVector *pV) const;
private:
	int mnNode;
	int mnNodeInternal;
	int mnDOF;
	int mINL;
	int mINU;
	std::vector<int> mvIndexL;
	std::vector<int> mvIndexU;
	std::vector<int> mvItemL;
	std::vector<int> mvItemU;
	std::vector<ublas::matrix<double> > mvD;
	std::vector<ublas::matrix<double> > mvAL;
	std::vector<ublas::matrix<double> > mvAU;
	std::vector<ublas::matrix<double> > mvALU;
	std::vector<double> mvWW;
	
	int mPrecond;

	// smoother
};

}

#endif /* MATRIXBCRS_H_ */
