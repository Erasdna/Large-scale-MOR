using SparseArrays, LinearAlgebra

export Problem, EllipticPDE
export DifferentialOperators2D

abstract type DifferentialOperators end
abstract type Problem end

struct DifferentialOperators2D
	"""
		2D differential operators
	"""
	∂x::SparseMatrixCSC
	∂y::SparseMatrixCSC
	∂²x::SparseMatrixCSC
	∂²y::SparseMatrixCSC
	function DifferentialOperators2D(N::Int64, hx::Float64, hy::Float64)
		#Fourth order discretisation

		D = spdiagm(
			-2 => (-1) .* ones(N - 2),
			-1 => (8) .* ones(N - 1),
			2 => ones(N - 2),
			1 => (-8) .* ones(N - 1),
		)

		DD = spdiagm(
			-2 => (-1) .* ones(N - 2),
			-1 => (16) .* ones(N - 1),
			0 => (-30) .* ones(N),
			2 => (-1) .* ones(N - 2),
			1 => (16) .* ones(N - 1),
		)
		DD[1,1]=12 * hx^2
		DD[1,2:end].=0.0
		DD[end,end]=12 * hx^2
		DD[end,1:end-1].=0.0

		id = sparse(I, N, N)
		new(kron(id, D) ./ (12 * hx), kron(D, id) ./ (12 * hy), kron(id, DD) ./ (12 * hx^2), kron(DD, id) ./ (12 * hy^2))
	end

end

struct EllipticPDE <: Problem
	"""
		Problem on the form ∇⋅(a(x,t)∇f(x,t)) = rhs(x,t)
		with corresponding grid and differential operators
	"""
	grid::Any
	a::Any
	rhs::Any
	∂D::DifferentialOperators2D
	function EllipticPDE(
		N::Int64,
		xmin::Float64,
		xmax::Float64,
		ymin::Float64,
		ymax::Float64,
		a,
		rhs,
	)
		@assert ymax > ymin
		@assert xmax > xmin

		new(collect(Iterators.product(range(xmin, xmax, N), range(ymin, ymax, N))), a, rhs, DifferentialOperators2D(N, (xmax - xmin) / N, (ymax - ymin) / N))
	end
end


